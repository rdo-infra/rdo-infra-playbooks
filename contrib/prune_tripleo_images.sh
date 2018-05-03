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
DIRS="master/rdo_trunk/ queens/rdo_trunk/ pike/rdo_trunk/ ocata/rdo_trunk/ newton/rdo_trunk/"

for imagedir in $DIRS
do
    path="${ROOT}/${imagedir}"
    # Build a list of patterns (symlink destinations) that will be used as a
    # whitelist (egrep -v)
    whitelist=$(find "${path}" -type l |xargs readlink |awk -F/ '{print $NF}' |sort |uniq |paste -sd '|')
    echo "Whitelist: ${whitelist}" | log

    # Get a list of candidates directories appropriate for deletion
    candidates=$(ls -ltr "${path}" |egrep -v "${whitelist}" |grep -v 'total 0' |awk '{print $9}')

    # Count how candidates there are
    count=$(echo "${candidates}" |wc -l)
    echo "Found ${count} eligible directories for pruning in ${path}" | log

    # Keep the last five
    if [ $count -gt 5 ]; then
        echo "Deleting $(expr $count - 5) directories..." | log
        to_delete=$(echo "${candidates}" | head -n-5)
        IFS=$'\n'
        for dir in $to_delete
        do
            folder="${path}${dir}"
            # rm -rf $folder
            echo "Deleted ${folder}" | log
        done
    else
        echo "Nothing to prune in ${path}" | log
    fi
done
