#!/bin/bash
#   Copyright Red Hat, Inc. All Rights Reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may
#   not use this file except in compliance with the License. You may obtain
#   a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#   License for the specific language governing permissions and limitations
#   under the License.
#
# Simple script to check if there are pending yum updates
# - Javier Peña <jpena@redhat.com>

# Nagios exit codes
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

function ExitScript() {
    status="${1}"
    message="${2}"

    echo "${message}"
    exit ${status}
}

function Usage() {
    echo "Usage: ${0}"
    return 0
}

# We need two arguments
if [ "${#}" -lt 0 ]; then
    Usage
    ExitScript $CRITICAL "Please provide the required arguments"
fi

# Check for dnf or yum
if type -p dnf > /dev/null; then
  YUM=dnf
else
  YUM=yum
fi

$YUM check-update --quiet > /dev/null
OUTPUT=$?

if [ $OUTPUT -eq 0 ]; then
    ExitScript $OK "OK: No available updates"
elif [ $OUTPUT -eq 100 ]; then
    ExitScript $WARNING "WARNING: There are pending updates"
fi

# This shouldn't happen
ExitScript $UNKNOWN "UNKNOWN: Unknown error trying to check for updates."
