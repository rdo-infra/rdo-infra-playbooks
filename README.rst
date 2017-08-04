rdo-infra-playbooks
===================
Playbooks to configure servers involved in the delivery of RDO.

Dependencies
============
- Pull required roles::

    ansible-galaxy install -r ansible-role-requirements.yml

- Setup config.yml (private credentials, etc.)

Setup monitoring master
=======================
- Setup master: ``ansible-playbook -e @config.yml -i hosts playbooks/setup_master.yml``

Setup monitoring clients
========================
- Setup client(s): ``ansible-playbook -e @config.yml -i hosts playbooks/setup_client.yml``

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
