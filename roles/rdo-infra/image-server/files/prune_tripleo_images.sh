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

# This script prunes logs from the images.rdoproject.org server.
function log () {
    # Print something to screen and log it to journalctl
    cat - | tee | systemd-cat -t "$(basename $0)" -p info
}

ROOT="/var/www/html/images"
# Trailing slashes are on purpose, those can be symlinks.
DIRS="aarch64/ocata/rdo_trunk/
 aarch64/pike/rdo_trunk/
 fedora28/stein/rdo_trunk/
 fedora28/master/rdo_trunk/
 ocata/rdo_trunk/
 queens/rdo_trunk/
 rocky/rdo_trunk/
 stein/rdo_trunk/
 train/rdo_trunk/
 centos8/master/rdo_trunk/
 centos8/ussuri/rdo_trunk/
 centos8/train/rdo_trunk/
 centos8/victoria/rdo_trunk/
 centos8/wallaby/rdo_trunk/
 centos9/wallaby/rdo_trunk/
 centos9/master/rdo_trunk/"
RETENTION=10

for imagedir in $DIRS
do
    path="${ROOT}/${imagedir}"
    # Build a list of patterns (symlink destinations) that will be used as a
    # whitelist (egrep -v)
    whitelist=$(find "${path}" -type l |xargs readlink |awk -F/ '{print $NF}' |sort |uniq |paste -sd '|')
    echo "Whitelist: ${whitelist}" | log

    # Get a list of candidates directories appropriate for deletion
    candidates=$(find "${path}" -mindepth 1 -maxdepth 1 -type d -mtime +${RETENTION} |egrep -v "${whitelist}")

    # Count how many candidates there are
    if [ -z "${candidates}" ]; then
        echo "No candidates for pruning in ${path}" | log
    else
        count=$(echo "${candidates}" |wc -l)
        echo "Found ${count} eligible directories for pruning in ${path}" | log

        for dir in $candidates
        do
            # To be sure, that we want to remove the directory,
            # remove content inside the dir, then remove empty location.
            find "${dir}" -type f -regextype egrep -regex ".*(artib-logs|delorean_hash|ironic-python-agent|overcloud-full|undercloud).(tar|tar.md5|tar.gz|tar.gz.md5|txt|qcow2|qcow2.md5)$" -mtime +${RETENTION} -delete
            find "${dir}" -type d -empty -delete
            echo "Deleted ${dir}" | log
        done
    fi
done
