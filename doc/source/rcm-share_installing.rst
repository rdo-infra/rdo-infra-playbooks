Technical details of the instance used for mirroring of RHOS Content in RDO Cloud
=================================================================================

Info
----

This document provides technical details of the instance described in Mirror of RHOS Content in RDO Cloud.
The intention is to split info about the usage of the instance and description of the technical background
(which is not needed if you are looking for the info how to use the share).


Access & Security
-----------------

**Rules**

Instance uses the default rules (Security Group: default) and there are two specific rules (Security Group: rcm-share)

=========   ==========    ===========   ============  ================
Direction   Ether Type    IP Protocol   Port Range    Remote IP Prefix
=========   ==========    ===========   ============  ================
Ingress     IPv4          TCP           22 (SSH)      0.0.0.0/0
Ingress     IPv4          TCP           4433 (HTTPS)  38.145.32.0/22 (floating IP range of RDO cloud instances)
=========   ==========    ===========   ============  ================


**Key Pairs**

These SSH keys are in use:

- 563-zcaplovi--key
- mburns-SSH
- rcm-share (keypair generated for this tenant only - will be used for sync cronjob etc)


Installation steps
------------------

Installation is done by Ansible image-server playbook. Same playbook is
configuring images server.


Content sync
------------

**Crontab**

<< FIXME >>

Following crontab entries were created for the sync (and cleanup) on the host *rcm-guest.app.eng.bos.redhat.com*:

::

  $ crontab -l
  # Crontab job for pushing content to an instance in RDO cloud
  # RHOS Release Delivery 2017-10-26
  0 * * * * /home/brq/zcaplovi/rdo_cloud_push.sh
  59 0 1 * * /home/brq/zcaplovi/push_log_cleanup.sh

Details about the scripts are in following section

**Sync and cleanup scripts**

All scripts (and files) are located in the directory /home/brq/zcaplovi/ on rcm-guest.app.eng.bos.redhat.com:

- *push_log_cleanup.sh* - script runs once per month (at 0:59 on 1st day of the month) and makes a copy of *rdo_cloud_push.log* (appending *`date +%F`* to the filename) and compresses it using gzip and truncates the original *rdo_cloud_push.log*
- *rdo_cloud_push.log* - plain "log" used to record start/stop of sync
- *rdo_cloud_push.py* - the sync script (called by rdo_cloud_push.sh)
- *rdo_cloud_push.sh* - BASH script for cron - it performs these actions:

  - writes *Sync with $BASHPID started at: `date`* at the end of the *rdo_cloud_push.log*
  - checks the presence of */home/brq/zcaplovi/rdo_cloud_push.lock*

    - if it exists it writes *Another sync in progress, exiting. Date: `date`* to the *rdo_cloud_push.log* and exits
    - if it does not exist, it creates the lockfile *rdo_cloud_push.lock* (writes the value of $BASHPID into it)

      - the sync is started
      - once finished it writes *Sync with $BASHPID ended at: `date`* to *rdo_cloud_push.log*
      - lockfile is removed and script is done

Note: The script rdo_cloud_push.py can be found in the Git repo rhos-release-standup-scripts


Scripts
-------
All scripts mentioned in this section are run on the host *rcm-guest.app.eng.bos.redhat.com*

**push_log_cleanup.sh**::

  #!/bin/bash
  echo Log closed and archived: `date` >> rdo_cloud_push.log
  cp rdo_cloud_push.log rdo_cloud_push.log.`date +%F`
  truncate -s 0 rdo_cloud_push.log
  gzip rdo_cloud_push.log.`date +%F`
  echo Log opened: `date` >> rdo_cloud_push.log

**rdo_cloud_push.py**
Latest version can be obtained from the git repo `rhos-release-standup-scripts <https://code.engineering.redhat.com/gerrit/rhos-release-standup-scripts>`_

**rdo_cloud_push.sh**::

  # Simple script for running the sync into the RDO cloud as cronjob
  # rdo_cloud_push.py is a Python script which syncs the data
  # rdo_cloud_push.log is just storing the date/time info about finished syncs
  # RHOS Release Deliveriy 2017-10-26
  # 2017-12-01 Prepared the script to be run evey hour (cronjob updated as weel)
  # 	- added lokfile mechanism (created at the start, removed at the end)
  #	- the value of $BASHPID will we stored in the file
  #	- PID will be recoreded in log
  #	- lokfile will prevent multiple parallel syncs


  #!/bin/bash
  echo Sync with PID: $BASHPID started at: `date` >> /home/brq/zcaplovi/rdo_cloud_push.log
  if [ -f /home/brq/zcaplovi/rdo_cloud_push.lock ];
      then
          echo Another sync in progress, exiting. Date: `date` >> /home/brq/zcaplovi/rdo_cloud_push.log
          exit 1
      else
          echo $BASHPID >> /home/brq/zcaplovi/rdo_cloud_push.lock
          /home/brq/zcaplovi/rdo_cloud_push.py
          echo Sync withPID: $BASHPID  ended at: `date` >> /home/brq/zcaplovi/rdo_cloud_push.log
          rm /home/brq/zcaplovi/rdo_cloud_push.lock
  fi
