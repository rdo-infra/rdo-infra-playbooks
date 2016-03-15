ansible-role-rdobase
====================
An ansible role to setup the common basics of an RDO Infrastructure server

Note: This playbook changes the SSH port and doing this both in-flight and
making it idempotent is a bit tricky. See tasks/ssh.yml for the implementation
to make this happen.