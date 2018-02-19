Setting up database replication for RDO Trunk
=============================================

The following instructions assume a two-node setup:

* A master MariaDB server
* A read-only replica server


* Both machines:

.. code-block:: shell-session
  
  # yum -y install mariadb-server
  # systemctl start mariadb
  # mysql_secure_installation (set new root password and accept all default options)
   

* On the master:

.. code-block:: shell-session
  
  # mkdir -p /etc/mysql/ssl
  # cd /etc/mysql/ssl
  ; Create CA cert
  # openssl genrsa 2048 > ca-key.pem
  # openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem
  ; Create server cert
  # openssl req -newkey rsa:2048 -days 365000 -nodes -keyout server-key.pem -out server-req.pem
  # openssl rsa -in server-key.pem -out server-key.pem
  # openssl x509 -req -in server-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
  ; Create client cert
  # openssl req -newkey rsa:2048 -days 365000 -nodes -keyout client-key.pem -out client-req.pem
  # openssl rsa -in client-key.pem -out client-key.pem
  #  openssl x509 -req -in client-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

  IMPORTANT: Make sure you use different common names for the CA, server and client certs

* On the replica

.. code-block:: shell-session

  # mkdir -p /etc/mysql/ssl
  # cd /etc/mysql/ssl
  # scp -p root@master:/etc/mysql/ssl/* .

* On both machines

.. code-block:: shell-session

  # vi /etc/my.cnf.d/ssl.cnf

  [mysqld]
  ssl
  ssl-ca=/etc/mysql/ssl/ca-cert.pem
  ssl-cert=/etc/mysql/ssl/server-cert.pem
  ssl-key=/etc/mysql/ssl/server-key.pem

  # systemctl restart mariadb

To check:

.. code-block:: shell-session

  # mysql -p
  > SHOW VARIABLES LIKE 'have_ssl';

* On both machines

.. code-block:: shell-session

  # vi /etc/my.cnf.d/mysql-clients.cnf, and add the following to the [mysql] section:

  ssl-ca=/etc/mysql/ssl/ca-cert.pem
  ssl-cert=/etc/mysql/ssl/client-cert.pem
  ssl-key=/etc/mysql/ssl/client-key.pem

* On the master

.. code-block:: shell-session

  ; Create database
  # mysql -p
  > create database dlrn;
  > grant all on dlrn.* to 'user'@'%' identified by 'password' REQUIRE SSL;
  > flush privileges;

* On the master, we can now populate the DB from a SQLite dump.

* On the master:

.. code-block:: shell-session
 
  # vi /etc/my.cnf.d/replication.cnf , and add the following:

  [mariadb]
  log-bin
  server_id=1
  log-basename=master1

  # systemctl restart mariadb
  # mysql -p
  > grant replication slave on *.* to dlrn_repl identified by 'password' REQUIRE SSL;

* On the replica:

.. code-block:: shell-session

  # vi /etc/my.cnf.d/replication.cnf , and add the following:

  [mariadb]
  log-bin
  server_id=2
  read-only=on

  # systemctl restart mariadb

* On the master:

.. code-block:: shell-session

  # mysql -p
  > flush tables with read lock;
  > show master status;  (take note of the position and log file name)

  # mysqldump -p dlrn > backup.sql

* On the replica:

  Fetch backup.sql from master, then

.. code-block:: shell-session

  ; Create database
  # mysql -p
  > create database dlrn;
  > grant all on dlrn.* to 'user'@'%' identified by 'password' REQUIRE SSL;
  > flush privileges;

  # mysql -p dlrn < backup.sql

* On the master:

.. code-block:: shell-session

  # mysql -p
  > unlock tables;

* On the replica:

.. code-block:: shell-session

  # mysql -p
  > change master to MASTER_HOST='192.168.122.227', MASTER_USER='dlrn_repl', MASTER_PASSWORD='password', MASTER_LOG_FILE='master1-bin.000001', MASTER_LOG_POS=2917492, MASTER_CONNECT_RETRY=10, MASTER_PORT=3306, MASTER_SSL=1;
  > start slave;
  > show slave status;


Failover procedure (simple one, creating a new database)
--------------------------------------------------------

* On the replica:

.. code-block:: shell-session

  # mysqldump -p dlrn > backup-replica.sql
  # mysql -p
  > create database dlrn_backup;
  > grant all on dlrn_backup.* to 'user'@'%' identified by 'password' REQUIRE SSL;
  > flush privileges;

  # mysql -p dlrn_backup < backup-replica.sql

Finally, remove the read-only parameter from ``/etc/my.cnf.d/replication.cnf``,
restart mariadb and reconfigure DLRN instances to use the replica.

Failback procedure (simple one, restoring from the new database)
----------------------------------------------------------------

* Stop all DLRN workers.

* On the replica:

.. code-block:: shell-session

  # systemctl stop mariadb
  (re-add the read-only parameter)
  # systemctl start mariadb

  # mysql -p 
  > stop slave;
  > flush tables with read lock;
 
  # mysqldump -p dlrn_backup > backup-good.sql

* On the master:

.. code-block:: shell-session

  (fetch the backup from the slave)
  # mysql -p dlrn < backup-good.sql

Reconfigure DLRN workers and restart


* On the replica:

.. code-block:: shell-session

  # mysql -p
  > unlock tables;
  > start slave;
  > drop database dlrn_backup;
