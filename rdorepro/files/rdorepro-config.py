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

"""Adapt zuul tenant configuration for local reproducer"""

from ruamel.yaml import YAML
yaml = YAML()


def load(path):
    return yaml.load(open(path).read())


def save(path, obj):
    yaml.dump(obj, open(path, "w"))


# Fetch https://softwarefactory-project.io/cgit/config/plain/zuul/rdo.yaml
rdorepro = load("rdo.yaml")
# Rename tenant
rdorepro[0]["tenant"]["name"] = "rdorepro"
source = rdorepro[0]["tenant"]["source"]
# Rename gerrit connection to sf-project.io
source["softwarefactory-project.io"] = source["gerrit"]
del source["gerrit"]
# Rename openstack.org connection to git.openstack.org
source["git.openstack.org"] = source["openstack.org"]
del source["openstack.org"]
# Replace config by rdorepro-config in shadow configuration
del source["rdoproject.org"]["config-projects"]
source["rdoproject.org"]["untrusted-projects"][0][
    "rdo-jobs"]["shadow"] = "rdorepro-config"
source["git.openstack.org"]["untrusted-projects"][0][
    "openstack-infra/zuul-jobs"]["shadow"] = "rdorepro-config"
save("zuul/rdorepro.yaml", rdorepro)
