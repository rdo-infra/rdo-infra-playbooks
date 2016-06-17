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
