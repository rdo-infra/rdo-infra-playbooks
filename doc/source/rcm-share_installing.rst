Technical details of the instance used for mirroring of RHOS Content in RDO Cloud
=================================================================================

Info
----

This document provides technical details of the instance described in Mirror of RHOS Content in RDO Cloud.
The intention is to split info about the usage of the instance and description of the technical background
(which is not needed if you are looking for the info how to use the share).


Access & Security
-----------------

**Rules**

Instance uses the default rules (Security Group: default) and there are two specific rules (Security Group: rcm-share)

=========   ==========    ===========   ============  ================
Direction   Ether Type    IP Protocol   Port Range    Remote IP Prefix
=========   ==========    ===========   ============  ================
Ingress     IPv4          TCP           22 (SSH)      0.0.0.0/0
Ingress     IPv4          TCP           4433 (HTTPS)  38.145.32.0/22 (floating IP range of RDO cloud instances)
=========   ==========    ===========   ============  ================


The iptables rules are also created for port 4433.


**Key Pairs**

These SSH keys are in use for rcn-uploader user:

- 563-zcaplovi--key
- mburns-SSH
- rcm-share (keypair generated for this tenant only - will be used for sync cronjob etc)


Installation steps
------------------

Whole configuration is done by Ansible image-server playbook.
