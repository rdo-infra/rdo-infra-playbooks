Technical details of the instance used as container image registry
==================================================================

Info
---

This document provides technical details of the instance described in Container image registry in RDO cloud. The intention is to split info about the usage of the instance and description of the technical background (which is not needed if you are looking for the info how to use the registry).


Technical details
-----------------

**Info about the instance**

==========  ==============================
**Name**	  rcm-registry
**Flavor**  m1.small
**VCPUs**   1 VCPU
**RAM**     2 GB
**Disk**    20 GB (attached on */dev/vda*)
**OS**      CentOS Linux 7
==========  ==============================

**Data volume**
===============   ============================
**Name**          rcm-registry
**Description**   Containers registry
**Size**          900 GiB
**Bootable**      No
**Encrypted**     No
**Attached On**   */dev/vdb*

Access & Security
-----------------

**Rules**

Instance uses the default rules (Security Group: default) and there is one specific rule (Security Group: rcm-registry)

=========   ==========    ===========   ==========  ================
Direction   Ether Type    IP Protocol   Port Range  Remote IP Prefix
=========   ==========    ===========   ==========  ================
Ingress     IPv4          TCP           5000        0.0.0.0/0
=========   ==========    ===========   ==========  ================

Key Pairs
---------

These SSH keys are in use:

- 563-zcaplovi--key

Installation steps
------------------

Installation is done by Ansible playbook (which expects that you have created the instance manually setting the above listed parameters and added its IP to the inventory). Basic list of steps done:

- Update system
- Install packages docker-distribution, httpd-tools and vim-enhanced
- Update configuration of the docker-distribution (place the provided config.yml to /etc/docker-distribution/registry)
- Prepare nad mount the share
- Create the self-signed SSL certificate for the registry
- Ensure that the docker-distribution service is started and enabled
- Enable port 5000 on the firewall
