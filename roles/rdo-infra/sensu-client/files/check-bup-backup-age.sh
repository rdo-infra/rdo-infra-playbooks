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
# Simple script to the age of a bup backup
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
    echo "Usage: ${0} <bup directory> <base dir in backup> <age in seconds> <use current month subdir>"
    return 0
}

# We need two arguments
if [ "${#}" -lt 4 ]; then
    Usage
    ExitScript $CRITICAL "Please provide the required arguments"
fi
BUP_DIR="${1}"
DIRECTORY="${2}"
THRESHOLD="${3}"
USE_DATE_SUBDIR="${4}"

if [ $USE_DATE_SUBDIR -eq 1 ]; then
    CURDATE=$(date +%Y-%m)
    BUP_DIR=${BUP_DIR}/${CURDATE}
fi

# Get timestamps
NOW=$(date +"%s")
FILE_DATE=$(sudo BUP_DIR=${BUP_DIR} /usr/local/bin/bup ls -l ${DIRECTORY} | grep -v latest | awk '{print $6}' |sort -r | head -n 1)
DATE_SHORT=$(echo $FILE_DATE | awk -F- '{print $1$2$3}')
TIMESTAMP=$(date -d "${DATE_SHORT}" +%s)

# Compare threshold
[[ $(( $NOW - $TIMESTAMP )) -gt $THRESHOLD ]] && ExitScript $CRITICAL "CRITICAL: Backup at ${BUP_DIR} is older than ${THRESHOLD} seconds: ${FILE_DATE}"
[[ $(( $NOW - $TIMESTAMP )) -lt $THRESHOLD ]] && ExitScript $OK "OK: Backup at ${BUP_DIR} is not older than ${THRESHOLD} seconds: ${FILE_DATE}"

# This shouldn't happen
ExitScript $UNKNOWN "UNKNOWN: Unable to check the backup age of ${BUP_DIR}."
