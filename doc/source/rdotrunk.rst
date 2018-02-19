**************************************
Troubleshooting RDO Trunk repositories
**************************************

RDO Trunk repositories are composed of several servers:

* ``trunk.rdoproject.org`` is the public instance hosting the repositories.
* ``trunk-primary.rdoproject.org`` is the main builder instance, where all
  CentOS packages for the different OpenStack releases supported by RDO are
  built.
* ``trunk-fedora.rdoproject.org`` is the builder instance for Fedora packages.

Each builder is associated to a user , so all repos and log files are found in
the home directory of that user. For example, user ``centos-queens`` contains
all Queens related repositories.

Failed builds
*************

When a package fails to build, a review is automatically opened in
``review.rdoproject.org``, linking back to the build log and the commit that
caused the failure. Tipically, no action is required in the systems, and we
just need to fix the spec file or upstream repository to get a working build.

No new builds after some time
*****************************

In some cases, we see that there are no new packages build for a given
release. This can be the symptom of an issue, or just that there were no new
commits for that release in the last hours/days.

We can check the reason by looking at the ``/home/<user>/dlrn-logs`` directory
for the builder (for example, /home/centos-queens/dlrn-logs), and looking at
the most recent ``dlrn-run.<date>.log`` file. If you see the following message,
there were no new commits recently:

.. code-block:: shell-session

    2018-02-19 09:11:33,392 INFO:dlrn:No commits to build.

You can also check if the cron job for the DLRN builder is enabled. It runs
``run-dlrn.sh`` periodically, and may have been disabled to do administrative
tasks, or as a response to an infrastructure issue. You can check the crontab
for a builder with:

.. code-block:: shell-session

    $ sudo crontab -l -u <user>

Additional links
****************

* `DLRN documentation <https://github.com/softwarefactory-project/DLRN/tree/master/doc/source>`_.
