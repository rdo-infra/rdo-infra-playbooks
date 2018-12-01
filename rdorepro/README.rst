review.rdoproject.org reproducer
================================

This directory contains playbook to reproduce the review.rdoproject.org CI
system locally for testing purpose. The setup playbook install
gerrit, zuul, nodepool, logserver and ara as well as a copy of the rdo
zuul config.

Setup playbook takes about 20 minutes, then zuul takes 30 minutes to initialize all
the project private keys and load the full configuration.
Backup playbook takes 30 seconds.
Restore playbook takes about 25 minutes to get zuul up and running with the config loaded.


Preparation
-----------

Prepare zuul access:
* Generate zuul key pair
* Add public key to softwarefactory-project.io and review.rdoproject.org gerrit user ssh-keys
* Write zuul key pair in secrets.yaml

Prepare rdo-cloud tenant
* Create network with router
* Virt-customize upstream-centos-7 to install the zuul key pair in zuul/.ssh/authorized_keys
* Upload upstream-centos-7 image
* Authorize port 22, 19885, 443
* Write username, project name and password in secrets.yaml

Prepare reproducer host,
* Spawn a centos-7 instance in the tenant:
  * Use CentOS-7-x86_64-GenericCloud-1804_02 without volume
  * flavor: m1.medium   (after setup, rootfs hold 5.1GB, mem usage is 1.5GB)
* Write ip address in hosts


Setup host
----------

* ansible-playbook -i hosts --ask-vault-pass setup.yaml
* Add "ip-address rdorepro.local" to your /etc/hosts
* Access deployment using "https://rdorepro.local"
* Login with github


Use the host
------------

* git clone git+ssh://GithubUsername@rdorepro.local:29418/rdorepro-demo
* Add zuul.yaml, e.g.:

.. code-block:: yaml

   - project:
       check:
         jobs:
           - periodic-tripleo-ci-centos-7-singlenode-featureset027-master

* Git commit && git review
* check https://rdorepro.local/ for job console stream
* To hold the node:

.. code-block:: console

  zuul autohold --tenant rdorepro --project rdorepro-demo --reason debug \
      --job periodic-tripleo-ci-centos-7-singlenode-featureset027-master

* Access the host using: ssh -i ~zuul/.ssh/id_rsa zuul@node-ip

* Re-enqueu the job:

.. code-block:: console

   zuul enqueue --tenant rdorepro --trigger gerrit --pipeline check \
        --project rdorepro-demo --change 1,1


Backup the host
---------------

* ansible-playbook -i hosts backup.yaml
* encrypt the backup.tgz and share it with the team


Restore the backup
------------------

* Repeat "Prepare rdo-cloud tenant" and "Prepare reproducer host",
  to change rdo-cloud tenant and avoid multiple nodepool using a single tenant
* ansible-playbook -i hosts --ask-vault-pass restore.yaml



TODO
----

* automate preparation and/or enable nodepool-builder
* setup mirror and te-broker host
* Update rdo zuul config
  When review.rdoproject.org/config changes, use this playbook to import change
  * ansible-playbook -i hosts update.yaml
