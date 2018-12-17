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
DIRS="fedora28/master/rdo_trunk fedora28/stein/rdo_trunk/ centos7/master/rdo_trunk/ centos7/stein/rdo_trunk/ centos7/rocky/rdo_trunk/ centos7/queens/rdo_trunk/ centos7/pike/rdo_trunk/ centos7/ocata/rdo_trunk/ centos7/newton/rdo_trunk/"
RETENTION=15

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
            rm -rf $dir
            echo "Deleted ${dir}" | log
        done
    fi
done
