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

# This script prunes Octavia images from the images.rdoproject.org server

function log () {
    # Print something to screen and log it to journalctl
    cat - | tee | systemd-cat -t "$(basename $0)" -p info
}

ROOT="/var/www/html/images/octavia"
DIRS="queens rocky stein master"
WHITELIST_FILE="amphora-x64-haproxy-centos.qcow2"
LOGFILE="/var/log/prunes/prune_octavia_$(date +%s).log"

RETENTION=15

for imagedir in $DIRS
do
  path="${ROOT}/${imagedir}"
  find $path -type f -mtime +${RETENTION} | grep -v $WHITELIST_FILE | while read file
  do
    echo $file >> $LOGFILE
    rm -f $file 
  done
done
