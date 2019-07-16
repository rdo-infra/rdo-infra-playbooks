Mirror of RHOS Content in RDO Cloud
===================================

Purpose
-------

The instance is serving content to the rest of the RDO cloud. It is mirroring internal repositories in RDO cloud which would be restricted to OSP developers.


Usage
-----

Content is shared via HTTP protocol, so use wget to download the RPMs you need in your script.

For installation (QuickStart or RHOS) use following options:

*rhos-release XY -O -H 38.145.34.141*

- O means only OSP related repos
- H overrides the download url to be the rdo-cloud instance

 
Access
------

The content is accessible only from RDO cloud instances (38.145.32.0/22 network)

You can access the content using floating IP of the instance - 38.145.34.141, full URL is:

*http://38.145.34.141/rcm-guest/*

For SSH access use the rcm-share key or contact Mike Burns or Zoltan Caplovic to add your key into authorized keys.

 
Q&A
---

**HELP! I need the wget package to run rhos-release!**

You can download the package to the undercloud host using curl:

*curl -O http://38.145.34.141/rcm-guest/wget-1.14-9.el7.x86_64.rpm*

and install the package using yum:

*yum localinstall wget-1.14-9.el7.x86_64.rpm*

**How to browse the content?**

Use lynx from any RDO cloud instance:

*lynx http://38.145.34.141/rcm-guest/*

**How to install packages synced to the RDO cloud instance?**

Individual packages can be installed using RPM:

*rpm -i http://38.145.34.141/rcm-guest/path/to/the/package.rpm*

or downloaded using wget and then installed locally. For installation of QuickStart etc see the section `Usage`_ above.

**What about images? Are they included?**

Overcloud and ipa qcow images are included in the rhosp-director-images rpm. Undercloud has no images that we ship, so there won't be any included.

**What about container images? Are they synced here?**

Yes, they are. Use the instance rcm-registry or RDO registry to obtain the images you need
