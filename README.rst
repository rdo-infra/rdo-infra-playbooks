rdo-monitoring
==============
Playbooks to configure Sensu monitoring components across RDO Infrastructure servers

Usage
=====
- Pull required roles::

    ansible-galaxy install -r requirements.yml

- Setup config.yml (private credentials, etc.)
- Setup master: ``ansible-playbook -i hosts playbooks/setup_master.yml``
- Setup client(s): ``ansible-playbook -i hosts playbooks/setup_client.yml``

Done !