Container image registry in RDO cloud
=====================================

Purpose
-------

The instance is serving content to the rest of the RDO cloud. It is storing container images needed for containerized deployments (RHOSP 12 and above).

Usage
-----

The registry is listening on 38.145.35.124:5000. Example of accessing the registry with skopeo:

::
    $ skopeo inspect docker://38.145.35.124:5000/rhosp12/openstack-redis:2018-05-29.1
    {
    "Name": "38.145.35.124:5000/rhosp12/openstack-redis",

    ...

    <snip>

    ...
    "vendor": "Red Hat, Inc.",
    "version": "12.0",
    "version-release": "12.0-20180529.1"
    },
    "Architecture": "amd64",
    "Os": "linux",
    "Layers": [
    "sha256:e0f71f706c2a1ff9efee4025e27d4dfd4f328190f31d16e11ef3283bc16d6842",
    "sha256:121ab4741000471a7e2ddc687dedb440060bf9845ca415a45e99e361706f1098",
    "sha256:4fb0a511e22b182712e67b85b18a27c81a408acf2ba79d95f0b8222958b1df8b",
    "sha256:886635bf6678937e0a841e0c1821ed3de0641b4eec3d01fa7aa2a71020168b52"
    ]
    }

Access
------

The container images registry is accessible from RDO cloud instances (38.145.32.0/22 network)


Q&A
---

**Which clients can I use to obtain the images?**

You can use either Docker or skopeo

**What to do with the message "FATA[0000] pinging docker registry returned: Get https://38.145.35.124:5000/v2/: x509: certificate signed by unknown authority"?**

You have to place the certificate oif the registry into your Docker client config (*/etc/docker/certs.d/*)
