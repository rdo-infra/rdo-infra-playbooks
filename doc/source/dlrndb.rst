**********************************
RDO Trunk database troubleshooting
**********************************

The RDO Trunk database is a simple MariaDB installation, with a master-replica
configuration:

* The master DB runs on ``dlrn-db.rdoproject.org``
* The replica DB (read-only) runs on ``backup.rdoproject.org``

Database access and replication is secured using TLS with client certificates.

To check the replication status, you can run the following commands on the
replica instance:

.. code-block:: shell-session

    $ sudo mysql -p
    MariaDB [(none)]> show slave status;

The important columns to check are:

* ``Slave_IO_State``: should be "Waiting for master to send event"
* ``Slave_IO_Running``: should be "Yes"
* ``Slave_SQL_Running``: should be "Yes"
* ``Seconds_Behind_Master``: should be 0 or a low value, otherwise we are
  having lag issues.

In case of issues with the database replication, refer to the
`MariaDB documentation <https://mariadb.com/kb/en/library/setting-up-replication/>`_
or :doc:`dbreplica`.
