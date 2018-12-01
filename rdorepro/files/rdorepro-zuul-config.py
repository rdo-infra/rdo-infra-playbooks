#!/bin/env python3
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

"""Adapt zuul configuration for local reproducer:
* Fix required project names,
* Remove upstream pipeline triggers
* Replace site_logs secrets with local secret
* Discard other secrets
"""

import io
import os
import subprocess

from ruamel.yaml import YAML
yaml = YAML()


def xunlink(path):
    try:
        os.unlink(path)
    except Exception:
        pass


def remove_config(config, ctype, cname):
    obj = None
    for cobj in config:
        if ctype in cobj.keys():
            if cobj[ctype]["name"] == cname:
                obj = cobj
                break
    if not obj:
        print("Couldn't find %s %s" % (ctype, cname))
        return
    config.remove(obj)


def load(path):
    return yaml.load(open(path).read())


def save(path, obj):
    yaml.dump(obj, open(path, "w"))


def pread(cmd):
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()
    return list(map(lambda x: x.decode('utf-8')[:-1], p.stdout.readlines()))


def create_config_pub_key():
    if os.path.exists("/var/lib/zuul/rdorepro.pub"):
        return
    import zuul.configloader
    import zuul.lib.encryption
    import zuul.configloader
    from zuul.lib.keystorage import KeyStorage

    class ZuulJobs:
        pass
    project = ZuulJobs()
    project.name = "rdorepro-config"
    tp = zuul.configloader.TenantParser(None, None, None, KeyStorage(
        "/var/lib/zuul/keys"))
    tp._loadProjectKeys("gerrit", project)
    pub = open("/var/lib/zuul/rdorepro.pub", "w")
    pub.write(zuul.lib.encryption.serialize_rsa_public_key(
        project.public_secrets_key).decode("utf-8"))
    pub.close()


# Remove unused
xunlink("zuul.d/github.yaml")
xunlink("zuul.d/upstream.yaml")
xunlink("zuul.d/ceph-ansible.yaml")

# fix jobs
jobs = load("zuul.d/jobs.yaml")
remove_config(jobs, "job", "config-check")
remove_config(jobs, "job", "config-update")
save("zuul.d/jobs.yaml", jobs)

jobs = load("zuul.d/tripleo-rdo-base.yaml")
for job_obj in jobs:
    job = job_obj["job"]
    if "config" in job.get("required-projects", []):
        job["required-projects"].remove("config")
save("zuul.d/tripleo-rdo-base.yaml", jobs)

# Fix secrets
secrets = load("zuul.d/secrets.yaml")
for secret_obj in secrets:
    secret = secret_obj["secret"]
    if secret["name"] == "site_logs":
        if secret["data"]["fqdn"] == "rdorepro.local":
            continue
        create_config_pub_key()
        key = yaml.load(io.StringIO("\n".join(pread([
            "/usr/share/sf-config/scripts/zuul-encrypt-secret.py",
            "/var/lib/zuul/rdorepro.pub", "ssh_private_key", "--infile",
            "/var/lib/software-factory/bootstrap-data/ssh_keys/"
            "zuul_logserver_rsa"]))))
        secret["data"] = {
            "url": "https://rdorepro.local/logs",
            "fqdn": "rdorepro.local",
            "path": "/var/www/logs",
            "ssh_username": "loguser",
            "ssh_private_key": key["ssh_private_key"],
            "ssh_known_hosts": list(filter(
                lambda x: "ssh-rsa" in x,
                pread(["ssh-keyscan", "rdorepro.local"])))[0],
        }
    else:
        # Remove secret
        for k in ("ssh_private_key", "private_key", "server_ca_cert",
                  "token", "jjb_config", "api_key", "password", "passw", ):
            if k in secret["data"]:
                secret["data"][k] = "Fake"
save("zuul.d/secrets.yaml", secrets)

# Remove pipelines and fix check
pipelines = load("zuul.d/pipelines.yaml")
for pipeline in ("gate", "post", "periodic", "release", "experimental",
                 "merge-check"):
    remove_config(pipelines, "pipeline", pipeline)
check = pipelines[0]["pipeline"]
check["trigger"]["rdoproject.org"] = [
    {"event": "comment-added",
     "comment": ".*rdorepro-local.*"}
]
check["trigger"]["gerrit"] = [
    {"event": "patchset-created"},
    {"event": "change-restored"},
    {"event": "comment-added",
     "comment": "(?i)^(Patch Set [0-9]+:)?( [\w\\+-]*)*(\n\n)?\s*recheck"},
]
try:
    del check["success"]["rdoproject.org"]
except Exception:
    pass
check["success"]["gerrit"] = {"Verified": 1}
try:
    del check["failure"]["rdoproject.org"]
except Exception:
    pass
check["failure"]["gerrit"] = {"Verified": -1}

save("zuul.d/pipelines.yaml", pipelines)

# Remove projects
projects = load("zuul.d/projects.yaml")
remove_config(projects, "project", "ceph/ceph-ansible")
remove_config(projects, "project", "config")
save("zuul.d/projects.yaml", projects)
