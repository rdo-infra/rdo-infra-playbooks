rdo-infra-playbooks
===================
Playbooks and roles to configure servers involved in the delivery of RDO.

Contributing
============

All reviews are done using Gerrit on review.rdoproject.org.

The project can be found on https://review.rdoproject.org/r/#/admin/projects/rdo-infra/rdo-infra-playbooks

Dependencies
============
- Pull required roles::

    ansible-galaxy install -r requirements.yml

- Pull required roles **only** if you are planning to set up the RDO registry, since it
  seems to conflict with the user task::

    ansible-galaxy install -r registry-requirements.yml

- For the monitoring roles, you will need to fetch the opstools-ansible role::

    cd roles/opstools-ansible
    git submodule update --init --recursive

Dealing with Secrets
====================

We use Ansible Vault (`ansible-vault` command) to hide some parameters
like service credentials or emails to avoid SPAM.

To make it easy all such files are named `\*.vault.yml` and git
attributes are defined to make diff-ing and merging easy.

Your config needs to be enhanced to tell git how to handle these files.
This is very easy, look at this URL for more info:

    https://github.com/building5/ansible-vault-tools


Setup base RDO server requirements
==================================
- Setup machine: ``ansible-playbook -i hosts.yml playbooks/base.yml``

Setup Jenkins slave for ci.centos.org environment
=================================================
- Setup machine: ``ansible-playbook -i hosts.yml playbooks/cico-slave.yml``

Setup monitoring master
=======================
- Setup master: ``ansible-playbook -i hosts.yml playbooks/sensu-server.yml``

Setup monitoring clients
========================
- Setup client(s): ``ansible-playbook -i hosts.yml playbooks/sensu-client.yml``

Setup RDO Registry
==================

::

    virtualenv ~/.venv
    . ~/.venv/bin/activate
    pip install -r roles/openshift/openshift-ansible/requirements.txt
    ansible-playbook -b -i inventory.yaml playbooks/registry-host-preparation.yml
    ansible-playbook -b -i inventory.yaml roles/openshift/openshift-ansible/playbooks/byo/openshift-node/network_manager.yml
    ansible-playbook -b -i inventory.yaml roles/openshift/openshift-ansible/playbooks/byo/config.yml
    ansible-playbook -b -i inventory.yaml playbooks/registry-project-creation.yml

Setup Websites
==============

The main website and the planet are generated using builders on a separate machine:

    ansible-playbook -i hosts.yml -t websites_builders playbooks/web.yml

The generated static pages as well as various redirections and the dashboard are on
a publishing machine:

    ansible-playbook -i hosts.yml -t websites playbooks/web.yml


Copyright
=========
::

 Copyright Red Hat, Inc. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License"); you may
 not use this file except in compliance with the License. You may obtain
 a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 License for the specific language governing permissions and limitations
 under the License
