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

Adding new systems to the inventory
===================================

The Ansible inventory is stored in the ``hosts.yml`` file. We also have some special,
per-system tags that allow us to describe additional inventory data that is not stored
elsewhere.

To add a new system:

- Create the required entry in ``hosts.yml``, adding it to any group the new system
  should belong to. Use the ``standard`` group if no there is no other group to assign to.

- Create a ``playbooks/host_vars/<hostname>/inventory.yml`` file, with the following
  contents::

    ---
    host_cloud: <cloud hosting the system>
    host_tenant: <tenant in cloud>
    host_service: <free-form string describing the service>
    host_automation:
      base: <link to playbooks setting up the base users, packages, etc.>
      service:
        - <list of pointers to additional playbooks, puppet modules, automation tools that set up the service>

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

Run the inventory playbook
==========================

::
    ansible-playbook -i hosts.yml playbooks/inventory.yml

The playbook will generate a series of html files at /tmp, named ``inventory-hostname.html``.
If you want to publish the html pages in a web server, copy the CSS file at ``contrib/styles.css``
in the same directory, and you will get a fancier output.

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
