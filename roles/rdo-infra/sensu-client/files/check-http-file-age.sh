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
# Simple script to monitor the file age of a remote file over HTTP
# - David Moreau Simard <dms@redhat.com>

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
    echo "Usage: ${0} <http://url/file> <seconds for critical>"
    return 0
}

# We need two arguments
if [ "${#}" -lt 2 ]; then
    Usage
    ExitScript $CRITICAL "Please provide the required arguments"
fi
URL="${1}"
TRESHOLD="${2}"

# Validate URL
curl -s -I ${URL} 2>&1 >/dev/null || ExitScript $CRITICAL "CRITICAL: Unable to fetch the URL: ${URL}"

# Get timestamps
NOW=$(date +"%s")
FILE_DATE=$(curl -s -I ${URL} 2>&1 |grep 'Last-Modified' |cut -d : -f2- |sed -e "s/^ *//")
TIMESTAMP=$(date --date="${FILE_DATE}" +"%s")

# Compare treshold
[[ $(( $NOW - $TIMESTAMP )) -gt $TRESHOLD ]] && ExitScript $CRITICAL "CRITICAL: File at ${URL} is older than ${TRESHOLD} seconds: ${FILE_DATE}"
[[ $(( $NOW - $TIMESTAMP )) -lt $TRESHOLD ]] && ExitScript $OK "OK: File at ${URL} is not older than ${TRESHOLD} seconds: ${FILE_DATE}"

# This shouldn't happen
ExitScript $UNKNOWN "UNKNOWN: Unable to check the file age of ${URL}."