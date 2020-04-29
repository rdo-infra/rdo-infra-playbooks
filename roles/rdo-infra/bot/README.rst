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

.. code::

    #plugin config Webserver {"HOST": "127.0.0.1", "PORT": 3142}

You can check the bot status with:

.. code::

    #status

A direct message will be sent to one of the bot administrators with the
status. Something like the following:

.. code::

    09:16:59 	<dmsimard>	#status
    09:17:00 	<rdobot>	Yes I am alive...
    09:17:03 	<rdobot>	    Plugins
    09:17:05 	<rdobot>	Status Name           
    09:17:06 	<rdobot>	A ACLs           
    09:17:07 	<rdobot>	A Backup         
    09:17:08 	<rdobot>	A ChatRoom       
    09:17:09 	<rdobot>	A Errbot-Rdo     
    09:17:10 	<rdobot>	A Errbot-Sensu   
    09:17:11 	<rdobot>	A Flows          
    09:17:12 	<rdobot>	A Health         
    09:17:13 	<rdobot>	A Help           
    09:17:14 	<rdobot>	A Plugins        
    09:17:15 	<rdobot>	A Utils          
    09:17:16 	<rdobot>	A VersionChecker 
    09:17:17 	<rdobot>	C Webserver      
    09:17:18 	<rdobot>	 A = Activated, D = Deactivated, B = Blacklisted, C = Needs to be configured
    09:17:19 	<rdobot>	 Load 0.36, 0.41, 0.38
    09:17:20 	<rdobot>	GC 0->126 1->10 2->4
