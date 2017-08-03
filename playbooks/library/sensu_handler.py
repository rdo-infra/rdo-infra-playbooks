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

DOCUMENTATION = '''
---
module: sensu_handler
author: "David Moreau Simard (@dmsimard)"
short_description: Manages Sensu handler configuration
version_added: 2.4
description:
  - Manages Sensu handler configuration
  - 'For more information, refer to the Sensu documentation: U(https://sensuapp.org/docs/latest/reference/handlers.html)'
options:
  state:
    description:
      - Whether the handler should be present or not
    choices: [ 'present', 'absent' ]
    required: False
    default: present
  name:
    description:
      - A unique name for the handler. The name cannot contain special characters or spaces.
    required: True
    default: null
  type:
    description:
      - The handler type
    choices: [ 'pipe', 'tcp', 'udp', 'transport', 'set' ]
    required: True
    default: null
  filter:
    description:
      - The Sensu event filter (name) to use when filtering events for the handler.
    required: False
    default: null
  filters:
    description:
      - An array of Sensu event filters (names) to use when filtering events for the handler.
      - Each array item must be a string.
    required: False
    default: null
  severities:
    description:
      - An array of check result severities the handler will handle.
      - 'NOTE: event resolution bypasses this filtering.'
    choices: [ 'warning', 'critical', 'unknown' ]
    required: False
    default: null
  mutator:
    description:
      - The Sensu event mutator (name) to use to mutate event data for the handler.
    required: False
    default: null
  timeout:
    description:
      - The handler execution duration timeout in seconds (hard stop).
      - Only used by pipe and tcp handler types.
    required: False
    default: 10
  handle_silenced:
    description:
      - If events matching one or more silence entries should be handled.
    required: False
    default: False
  handle_flapping:
    description:
      - If events in the flapping state should be handled.
    required: False
    default: False
  command:
    description:
      - The handler command to be executed.
      - The event data is passed to the process via STDIN.
      - 'NOTE: the command attribute is only required for Pipe handlers (i.e. handlers configured with "type": "pipe").'
    required: False
    default: null
  socket:
    description:
      - The socket definition scope, used to configure the TCP/UDP handler socket.
      - 'NOTE: the socket attribute is only required for TCP/UDP handlers (i.e. handlers configured with "type": "tcp" or "type": "udp").'
    required: False
    default: null
  pipe:
    description:
      - The pipe definition scope, used to configure the Sensu transport pipe.
      - 'NOTE: the pipe attribute is only required for Transport handlers (i.e. handlers configured with "type": "transport").'
    required: False
    default: null
  handlers:
    description:
      - An array of Sensu event handlers (names) to use for events using the handler set.
      - Each array item must be a string.
      - 'NOTE: the handlers attribute is only required for handler sets (i.e. handlers configured with "type": "set").'
    required: True
    default: null
requirements: [ ]
'''

EXAMPLES = '''
# Configure a handler that sends event data as STDIN (pipe)
- name: Configure IRC Sensu handler
  sensu_handler:
    name: "irc_handler"
    type: "pipe"
    command: "/usr/local/bin/notify-irc.sh"
    severities:
      - "ok"
      - "critical"
      - "warning"
      - "unknown"
    timeout: 15
  notify:
    - Restart sensu-client
    - Restart sensu-server

# Delete a handler
- name: Delete IRC Sensu handler
  sensu_handler:
    name: "irc_handler"
    state: "absent"

# Example of a TCP handler
- name: Configure TCP Sensu handler
  sensu_handler:
    name: "tcp_handler"
    type: "tcp"
    timeout: 30
    socket:
      host: "10.0.1.99"
      port: 4444
  register: handler
  notify:
    - Restart sensu-client
    - Restart sensu-server

- name: Secure Sensu handler configuration file
  file:
    path: "{{ handler['file'] }}"
    owner: "sensu"
    group: "sensu"
    mode: "0600"
'''

RETURN = '''
config:
  description: Effective handler configuration, when state is present
  returned: success
  type: dict
  sample: {'name': 'irc', 'type': 'pipe', 'command': '/usr/local/bin/notify-irc.sh'}
file:
  description: Path to the handler configuration file
  returned: success
  type: string
  sample: "/etc/sensu/conf.d/handlers/irc.json"
name:
  description: Name of the handler
  returned: success
  type: string
  sample: "irc"
'''

from ansible.module_utils.basic import AnsibleModule
import errno
import json
import os


def required_arg(type):
    """ Returns the required argument for a type """
    return {
        'pipe': 'command',
        'tcp': 'socket',
        'udp': 'socket',
        'transport': 'pipe',
        'set': 'handlers'
    }[type]


def main():
    module = AnsibleModule(argument_spec=dict(
        state=dict(type='str', required=False, choices=['present', 'absent'], default='present'),
        name=dict(type='str', required=True),
        type=dict(type='str', required=False, choices=['pipe', 'tcp', 'udp', 'transport', 'set']),
        filter=dict(type='str', required=False),
        filters=dict(type='list', required=False),
        severities=dict(type='list', required=False),
        mutator=dict(type='dict', required=False),
        timeout=dict(type='int', required=False, default=10),
        handle_silenced=dict(type='bool', required=False, default=False),
        handle_flapping=dict(type='bool', required=False, default=False),
        command=dict(type='str', required=False),
        socket=dict(type='dict', required=False),
        pipe=dict(type='dict', required=False),
        handlers=dict(type='list', required=False),
    ))

    state = module.params['state']
    name = module.params['name']
    path = '/etc/sensu/conf.d/handlers/{0}.json'.format(name)

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
        # Type is required only if state == present
        if module.params['type'] is None:
            module.fail_json(msg="missing required arguments: type")

    # Some arguments are required depending on the type
    required = required_arg(module.params['type'])
    if module.params[required] is None:
        module.fail_json(msg="missing required arguments: {0}".format(required))

    # Build handler configuration from module arguments
    config = {'handlers': {name: {}}}
    args = ['type', 'filter', 'filters', 'severities', 'mutator', 'timeout',
            'handle_silenced', 'handle_flapping', 'command', 'socket',
            'pipe', 'handlers']

    for arg in args:
        if arg in module.params and module.params[arg] is not None:
            config['handlers'][name][arg] = module.params[arg]

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
        module.exit_json(msg='Handler configuration is already up to date',
                         config=config['handlers'][name],
                         file=path,
                         name=name)

    # Validate that directory exists before trying to write to it
    if not os.path.exists(os.path.dirname(path)):
        try:
            os.makedirs(os.path.dirname(path))
        except OSError as e:
            module.fail_json(msg='Unable to create {0}: {1}'.format(os.path.dirname(path),
                                                                    str(e)))

    try:
        with open(path, 'w') as handler:
            handler.write(json.dumps(config, indent=4))
            module.exit_json(msg='Handler configuration updated',
                             changed=True,
                             config=config['handlers'][name],
                             file=path,
                             name=name)
    except (OSError, IOError) as e:
        module.fail_json(msg='Unable to write file {0}: {1}'.format(path,
                                                                    str(e)))

if __name__ == '__main__':
    main()
