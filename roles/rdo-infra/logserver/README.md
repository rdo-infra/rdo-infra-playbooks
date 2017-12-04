# ansible-role-logserver

This role sets up a logserver based on
[os-loganalyze](https://github.com/openstack-infra/os-loganalyze), which is
capable of serving logs from both local files and from a swift object storage.

It is possible to set up the server with SSL using certbot. The role assumes
that the underlying system is CentOS.

The role needs the following variables customized before a run:

- `logserver_swift_auth_url`
- `logserver_swift_username`
- `logserver_swift_password`
- `logserver_swift_tenant_name`
