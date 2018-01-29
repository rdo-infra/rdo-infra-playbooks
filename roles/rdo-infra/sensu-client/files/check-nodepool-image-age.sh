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
# Simple script to the age of a nodepool image
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
    echo "Usage: ${0} <image name> <max age in days>"
    return 0
}

# We need two arguments
if [ "${#}" -lt 2 ]; then
    Usage
    ExitScript $CRITICAL "Please provide the required arguments"
fi

IMAGE_NAME="${1}"
THRESHOLD="${2}"

# Get timestamps

timestamps=$(sudo nodepool image-list | grep -w $IMAGE_NAME | awk -F\| '{print $9}')

while read line
do
    days=$(echo $line | awk -F: '{print $1}')
    if [ $days -lt $THRESHOLD ]; then
       ExitScript $OK "OK: Image ${IMAGE_NAME} is not older than ${THRESHOLD} days"
    fi
done <<< "$timestamps"

ExitScript $CRITICAL "CRITICAL: Image ${IMAGE_NAME} is older than ${THRESHOLD} days"
