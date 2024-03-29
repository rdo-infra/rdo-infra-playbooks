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

Dealing with Secrets
====================

We use Ansible Vault (`ansible-vault` command) to hide some parameters
like service credentials or emails to avoid SPAM.

To make it easy all such files are named `\*.vault.yml` and git
attributes are defined to make diff-ing and merging easy.

Your config needs to be enhanced to tell git how to handle these files.
This is very easy, look at this URL for more info:

    https://github.com/building5/ansible-vault-tools

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

Setup Jenkins agent for ci.centos.org environment
=================================================
- Setup machine: ``ansible-playbook -i hosts.yml playbooks/cico-agent.yml``

Setup Websites
==============

The main website and the planet are generated using builders on a separate machine:

    ansible-playbook -i hosts.yml -t websites_builders playbooks/web.yml

The generated static pages as well as various redirections and the dashboard are on
a publishing machine:

    ansible-playbook -i hosts.yml -t websites playbooks/web.yml

Setup Mails
===========

The mail and mailing-list servers (current Mailman 2 and future Mailman 3):

    ansible-playbook -i hosts.yml playbooks/mail.yml

Setup images.rdoproject.org
===========================

::
    ansible-playbook -i hosts.yml playbooks/images.yml

The playbook assumes that the base playbook has already been executed, since it relies on
the SSL certificate being created.


Run the inventory playbook
==========================

::
    ansible-playbook -i hosts.yml playbooks/inventory.yml

The playbook will generate a series of html files at /tmp/rdo-inventory. There is an index
file and css associated, so you can just transfer all files to a web page and serve them
from there.


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
