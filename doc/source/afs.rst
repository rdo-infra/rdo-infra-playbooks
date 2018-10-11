Setting up the RDO mirror of the OpenStack AFS infrastructure
=============================================================

The RDO infrastructure contains a mirror of the `OpenStack AFS <https://docs.openstack.org/infra/system-config/afs.html>`_
distributed file system, used to reduce the network load on CI jobs.

The setup procedure for this AFS mirror is based on the openstack-infra Puppet
modules, with some modifications described below.

**WARNING**: if we want to set this up on CentOS 7.5 or later, we will need at
least OpenAFS 1.6.22.3, due to a `known issue <https://www.openafs.org/dl/openafs/1.6.22.3/RELNOTES-1.6.22.3>`_.
At the time of this writing, the current version in https://tarballs.openstack.org/project-config/package-afs-centos7
is 1.6.16.

Setup steps
***********

* Install puppet 3.6.2 from EPEL (the OpenStack Infra puppet modules do not support puppet 4)

.. code-block:: shell-session

  # yum -y install epel-release
  # yum -y install puppet

* Clone https://github.com/openstack-infra/puppet-openstackci, apply under-review patches for CentOS 7 support:

.. code-block:: shell-session

  # git clone https://github.com/openstack-infra/puppet-openstackci
  # cd puppet-openstackci
  # git fetch https://git.openstack.org/openstack-infra/puppet-openstackci refs/changes/76/529376/17 && git cherry-pick FETCH_HEAD
  # git fetch https://git.openstack.org/openstack-infra/puppet-openstackci refs/changes/39/528739/23 && git cherry-pick FETCH_HEAD

* Install puppet module. Do not use puppet module build/puppet module install, since the openstackci module may pull way more requirements than needed for the AFS mirror setup.

.. code-block:: shell-session

  # cd /etc/puppet/modules
  # mkdir openstackci
  # cd openstackci
  # cp -pr ${HOME}/puppet-openstackci/* .

* Clone and install some openstack-infra puppet modules, required by openstackci:

.. code-block:: shell-session

  # git clone https://github.com/openstack-infra/puppet-httpd
  # git clone https://github.com/openstack-infra/puppet-logrotate
  # git clone https://github.com/openstack-infra/puppet-kerberos
  # git clone https://github.com/openstack-infra/puppet-openafs

  # for module in httpd logrotate kerberos openafs; do
  > pushd puppet-$module
  > puppet module build
  > puppet module install ${HOME}/puppet-$module/pkg/*.tar.gz
  > popd
  > done

* Install other puppet module dependencies

.. code-block:: shell-session

  # puppet module install puppetlabs-ntp --version 3.2.1

* Create the following Puppet file (site.pp):

.. code-block:: puppet

    class { '::openstackci::mirror':
      vhost_name  => 'mirror.regionone.rdo-cloud.rdoproject.org',
      mirror_root => '/afs/openstack.org/mirror',
    }

    class { 'openafs::client':
      cell         => 'openstack.org',
      realm        => 'OPENSTACK.ORG',
      admin_server => 'kdc.openstack.org',
      cache_size   => 50000000,  # 50GB
      kdcs         => [
        'kdc01.openstack.org',
        'kdc02.openstack.org',
      ],
    } 

* Then apply the manifest:

.. code-block:: shell-session

  # puppet apply site.pp
