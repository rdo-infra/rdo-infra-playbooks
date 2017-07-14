#!/bin/bash
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