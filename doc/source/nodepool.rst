***************************
Nodepool VM troubleshooting
***************************

The Nodepool configuration is defined in the `config project <https://review.rdoproject.org/r/gitweb?p=config.git;a=blob;f=nodepool/nodepool.yaml;h=e93f9a95a92b0bbe0a6c2597e221468eb8d34578;hb=refs/heads/master>`_ 
managed by ``review.rdoproject.org``. 

When reviews are stuck in the Zuul queue, and we see no progress, it is likely
that Nodepool is finding some trouble spawning new instances. We can follow
these steps to troubleshoot:

* First, we can check the `Jenkins page <https://review.rdoproject.org/jenkins/>`_
  for review.rdoproject.org, and find if VMs of each required type are
  available for Jenkins.

* If Jenkins has available VMs, we need to check for a potential disconnect
  between what Jenkins thinks is available, and what Nodepool thinks. Run
  the following command on review.rdoproject.org:

  .. code-block:: bash

      $ sudo nodepool list

  Then, check if the VMs listed as "ready" by Nodepool are also seen by
  Jenkins. If they are not, have a look at ``/var/log/nodepool/nodepool.log``
  to find the source of the disconnection.

* If Jenkins cannot see any VMs, we also need to check the Nodepool side using
  ``nodepool list``. We may find that Nodepool cannot spawn new VMs for some
  reason. Is that is the case, check ``/var/log/nodepool/nodepool.log`` for
  potential issues, such as:

  - Cloud provider error that prevents new VMs from starting or getting an IP.
  - Quota issues that prevent new VMs from being created.
  - Configuration change that modified the password for the user in the
    Nodepool configuration (you can check ``/var/lib/nodepool/.config/openstack/clouds.yaml``).

* If additional logging is required, you can edit ``/etc/nodepool/logging.conf``
  and set level to ``DEBUG``.

***************************************
Nodepool Image creation troubleshooting
***************************************

In some cases, the Nodepool builder can fail to create a new image, which
has caused some blockers in the past. In the review.rdoproject.org environment,
we have a separate builder node ``nb01.review.rdoproject.org``, only accessible
from review.rdoproject.org.

Some configuration details to keep in mind:

* You can check the build logs for new images at ``/var/www/nodepool-log``.
  Search for the string ``diskimage-builder version 2.8.0`` to get to the
  beginning of the build.

* Build logs are also available remotely at `this location <https://review.rdoproject.org/nodepool-log/>`_.

* Until review.rdoproject.org is migrated to use Zuul v3, the upstream DIB
  elements used to build new images are not synchronized anymore, so they are
  frozen at ``/opt/git/openstack-infra/project-config/nodepool/elements``. They
  also have some local patches added to fix issues.

Additional links
****************

* `Nodepool operator documentation <https://docs.openstack.org/infra/nodepool/operation.html>`_.
