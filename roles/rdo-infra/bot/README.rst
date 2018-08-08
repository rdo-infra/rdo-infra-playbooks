ansible-role-rdobot
===================
An ansible role to install and setup rdobot

Troubleshooting
===============

The bot will have two open connections:

- One to the Freenode IRC server
- An mini httpd server where it will listen for connections from Sensu.

If the httpd server is not started, you may need to send the bot the following
command via an IRC direct message:

    #plugin config Webserver {"HOST": "127.0.0.1", "PORT": 3142}

You can check the bot status with:

    #status

A direct message will be sent to one of the bot administrators with the
status.
