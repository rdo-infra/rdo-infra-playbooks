#!/usr/bin/python

# (c) 2017, Red Hat Inc.
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

ANSIBLE_METADATA = {
    'metadata_version': '1.0',
    'status': ['preview'],
    'supported_by': 'community'
}

# Arguments, defaults and documentation as provided upstream:
# https://sensuapp.org/docs/1.0/reference/clients.html
DOCUMENTATION = '''
---
module: sensu_client
author: "David Moreau Simard (@dmsimard)"
short_description: Manages Sensu client configuration
version_added: 2.4
description:
  - Manages Sensu client configuration
options:
  state:
    description:
      - Whether the client should be present or not
    choices: [ 'present', 'absent' ]
    required: false
    default: present
  path:
    description:
      - Path to the json file for the client to be added/removed
    required: false
    default: /etc/sensu/conf.d/client.json
  name:
    description:
      - A unique name for the client. The name cannot contain special characters or spaces.
    required: False
    default: System hostname as determined by Ruby Socket.gethostname (provided by Sensu)
  address:
    description:
      - An address to help identify and reach the client. This is only informational, usually an IP address or hostname.
    required: False
    default: Non-loopback IPv4 address as determined by Ruby Socket.ip_address_list (provided by Sensu)
  subscriptions:
    description:
      - An array of client subscriptions, a list of roles and/or responsibilities assigned to the system (e.g. webserver).
      - These subscriptions determine which monitoring checks are executed by the client, as check requests are sent to subscriptions.
      - The subscriptions array items must be strings.
    required: True
    default: null
  safe_mode:
    description:
      - If safe mode is enabled for the client. Safe mode requires local check definitions in order to accept a check request and execute the check.
    choices: [ 'true', 'false' ]
    required: False
    default: false
  redact:
    description:
      - Client definition attributes to redact (values) when logging and sending client keepalives.
    required: False
    default: null
  socket:
    description:
      - The socket definition scope, used to configure the Sensu client socket.
    required: False
    default: null
  keepalives:
    description:
      - If Sensu should monitor keepalives for this client.
    choices: [ 'true', 'false' ]
    required: False
    default: true
  keepalive:
    description:
      - The keepalive definition scope, used to configure Sensu client keepalives behavior (e.g. keepalive thresholds, etc).
    required: False
    default: null
  registration:
    description:
      - The registration definition scope, used to configure Sensu registration event handlers.
    required: False
    default: null
  deregister:
    description:
      - If a deregistration event should be created upon Sensu client process stop.
    choices: [ 'true', 'false' ]
    required: False
    default: false
  deregistration:
    description:
      - The deregistration definition scope, used to configure automated Sensu client de-registration.
    required: False
    default: null
  ec2:
    description:
      - The ec2 definition scope, used to configure the Sensu Enterprise AWS EC2 integration (Sensu Enterprise users only).
    required: False
    default: null
  chef:
    description:
      - The chef definition scope, used to configure the Sensu Enterprise Chef integration (Sensu Enterprise users only).
    required: False
    default: null
  puppet:
    description:
      - The puppet definition scope, used to configure the Sensu Enterprise Puppet integration (Sensu Enterprise users only).
    required: False
    default: null
  servicenow:
    description:
      - The servicenow definition scope, used to configure the Sensu Enterprise ServiceNow integration (Sensu Enterprise users only).
    required: False
    default: null
requirements: [ ]
'''

EXAMPLES = '''
# Minimum possible configuration
- name: Configure Sensu client
  sensu_client:
    subscriptions:
      - default

# With customization
- name: Configure Sensu client
  sensu_client:
    name: "{{ ansible_fqdn }}"
    address: "{{ ansible_default_ipv4['address'] }}"
    path: "/etc/sensu/conf.d/clients/{{ ansible_fqdn }}.json"
    custom:
      - priority: high
      - region: east
    subscriptions:
      - default
      - webserver
    redact:
      - password
    socket:
      bind: 127.0.0.1
      port: 3030
    keepalive:
      thresholds:
        warning: 180
        critical: 300
      handlers:
        - email
      custom:
        - broadcast: irc
      occurrences: 3
  notify:
    - Restart sensu-client

- name: Secure Sensu client configuration file
  file:
    path: "/etc/sensu/conf.d/clients/{{ ansible_fqdn }}.json"
    owner: "sensu"
    group: "sensu"
    mode: "0600"
'''

RETURN = '''
config:
  description: Effective client configuration, when state is present
  returned: success
  type: dict
  sample: {'name': 'client', 'subscriptions': ['default']}
'''

from ansible.module_utils.basic import AnsibleModule
import errno
import json
import os


def main():
    module = AnsibleModule(argument_spec=dict(
        state=dict(type='str', required=False, choices=['present', 'absent'], default='present'),
        path=dict(type='str', required=False, default='/etc/sensu/conf.d/client.json'),
        name=dict(type='str', required=False),
        address=dict(type='str', required=False),
        subscriptions=dict(type='list', required=False),
        safe_mode=dict(type='bool', required=False, default=False),
        redact=dict(type='list', required=False),
        socket=dict(type='dict', required=False),
        keepalives=dict(type='bool', required=False, default=True),
        keepalive=dict(type='dict', required=False),
        registration=dict(type='dict', required=False),
        deregister=dict(type='bool', required=False),
        deregistration=dict(type='dict', required=False),
        ec2=dict(type='dict', required=False),
        chef=dict(type='dict', required=False),
        puppet=dict(type='dict', required=False),
        servicenow=dict(type='dict', required=False)
    ))

    state = module.params['state']
    path = module.params['path']

    if state == 'absent':
        try:
            os.remove(path)
            msg = '{path} deleted successfully'.format(path=path)
            module.exit_json(msg=msg, changed=True)
        except OSError as e:
            if e.errno == errno.ENOENT:
                # Idempotency: it's okay if the file doesn't exist
                msg = '{path} already does not exist'.format(path=path)
                module.exit_json(msg=msg)
            else:
                msg = 'Exception when trying to delete {path}: {exception}'
                module.fail_json(msg=msg.format(path=path, exception=str(e)))
    else:
        # Subscriptions is required only if state == present
        if module.params['subscriptions'] is None:
            module.fail_json(msg="missing required arguments: subcriptions")

    # Build client configuration from module arguments
    config = {}
    args = ['name', 'address', 'subscriptions', 'safe_mode', 'redact',
            'socket', 'keepalives', 'keepalive', 'registration', 'deregister',
            'deregistration', 'custom', 'ec2', 'chef', 'puppet', 'servicenow']

    for arg in args:
        if arg in module.params and module.params[arg] is not None:
            config[arg] = module.params[arg]

    # Load the current config, if there is one, so we can compare
    current_config = None
    try:
        current_config = json.load(open(path, 'r'))
    except IOError:
        # File does not exist or something like that
        pass
    except ValueError:
        # Bad JSON or something like that
        pass

    if current_config is not None and current_config == config:
        # Config is the same, let's not change anything
        module.exit_json(msg='Client configuration is already up to date', config=config)

    with open(path, 'w') as client:
        client.write(json.dumps(config, indent=4))
        module.exit_json(msg='Client configuration updated', changed=True, config=config)

if __name__ == '__main__':
    main()
