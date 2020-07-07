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

# This script prunes logs from the logs.rdoproject.org server.
function log () {
    # Print something to screen and log it to journalctl
    cat - | tee | systemd-cat -t "$(basename $0)" -p info
}

LOGDIR="/var/log/prunes"
# Use a lock file to ensure we do not run two prunes at the same time
LOCK="/root/prune.lock"

exec 200>$LOCK
if !  flock -n 200
then
    echo "Lock file $LOCK is held by another process."
    echo "Another prune operation is already running, please try again after disabling it."
    exit 1
fi


# Make sure log directory exists
mkdir -p "${LOGDIR}"
export LOGFILE="${LOGDIR}/logserver_$(date +%s).log"
echo "Log file: ${LOGFILE}" | log

ROOT="/var/www/html"
read -r -d '' WHITELIST << EOM
review.rdoproject.org
review.rdoproject.org/periodic
review.rdoproject.org/openstack-periodic
review.rdoproject.org/openstack-periodic-integration-stable2
review.rdoproject.org/openstack-periodic-integration-stable2-centos7
review.rdoproject.org/periodic/review.rdoproject.org/openstack/octavia/master
review.rdoproject.org/periodic/review.rdoproject.org/openstack/octavia/ocata-rdo-patches
review.rdoproject.org/periodic/review.rdoproject.org/openstack/octavia/stable
review.rdoproject.org/periodic/review.rdoproject.org/openstack/octavia/stable/liberty
review.rdoproject.org/periodic/review.rdoproject.org/openstack/octavia/stable/mitaka
review.rdoproject.org/periodic/review.rdoproject.org/openstack/octavia/newton-rdo-patches
review.rdoproject.org/periodic/review.rdoproject.org/openstack/octavia/pike-rdo-patches
review.rdoproject.org/opendev.org/openstack/octavia/master
review.rdoproject.org/opendev.org/openstack/octavia/stable/queens
review.rdoproject.org/openstack-periodic/git.openstack.org
review.rdoproject.org/openstack-periodic/git.openstack.org/openstack-infra
review.rdoproject.org/openstack-periodic/git.openstack.org/openstack-infra/tripleo-ci/master
review.rdoproject.org/openstack-periodic-integration-stable2/opendev.org
review.rdoproject.org/openstack-periodic-integration-stable2/opendev.org/openstack
review.rdoproject.org/openstack-periodic-integration-stable2/opendev.org/openstack/tripleo-ci
review.rdoproject.org/openstack-periodic-integration-stable2/opendev.org/openstack/tripleo-ci/master
review.rdoproject.org/openstack-periodic-integration-stable2/git.openstack.org
review.rdoproject.org/openstack-periodic-integration-stable2/git.openstack.org/openstack-infra
review.rdoproject.org/openstack-periodic-integration-stable2/git.openstack.org/openstack-infra/tripleo-ci
review.rdoproject.org/openstack-periodic-integration-stable2/git.openstack.org/openstack-infra/tripleo-ci/master
review.rdoproject.org/openstack-periodic-integration-stable2-centos7/opendev.org
review.rdoproject.org/openstack-periodic-integration-stable2-centos7/opendev.org/openstack
review.rdoproject.org/openstack-periodic-integration-stable2-centos7/opendev.org/openstack/tripleo-ci
review.rdoproject.org/openstack-periodic-integration-stable2-centos7/opendev.org/openstack/tripleo-ci/master
review.rdoproject.org/openstack-periodic-integration-stable2-centos7/git.openstack.org
review.rdoproject.org/openstack-periodic-integration-stable2-centos7/git.openstack.org/openstack-infra
review.rdoproject.org/openstack-periodic-integration-stable2-centos7/git.openstack.org/openstack-infra/tripleo-ci
review.rdoproject.org/openstack-periodic-integration-stable2-centos7/git.openstack.org/openstack-infra/tripleo-ci/master
review.rdoproject.org/openstack-regular/
review.rdoproject.org/openstack-regular/opendev.org/
review.rdoproject.org/openstack-regular/opendev.org/openstack/
review.rdoproject.org/openstack-regular/opendev.org/openstack/tripleo-ci/
review.rdoproject.org/openstack-regular/opendev.org/openstack/tripleo-ci/master/
review.rdoproject.org/openstack-periodic-integration-main/
review.rdoproject.org/openstack-periodic-integration-main/opendev.org/
review.rdoproject.org/openstack-periodic-integration-main/opendev.org/openstack/
review.rdoproject.org/openstack-periodic-integration-main/opendev.org/openstack/tripleo-ci/
review.rdoproject.org/openstack-periodic-integration-main/opendev.org/openstack/tripleo-ci/master/
review.rdoproject.org/openstack-periodic-integration-stable1/
review.rdoproject.org/openstack-periodic-integration-stable1/opendev.org/
review.rdoproject.org/openstack-periodic-integration-stable1/opendev.org/openstack/
review.rdoproject.org/openstack-periodic-integration-stable1/opendev.org/openstack/tripleo-ci/
review.rdoproject.org/openstack-periodic-integration-stable1/opendev.org/openstack/tripleo-ci/master/
ci.centos.org
thirdparty
EOM
echo "Whitelist: ${WHITELIST}" | log

RETENTION="21"
echo "Retention: ${RETENTION} days" | log

echo "Starting prune run..." | log
df -h | log
df -i | log

# Make sure we don't delete these if they haven't been modified recently
for dir in $WHITELIST
do
    touch ${ROOT}/$dir
done

function result_count () {
    echo "$(wc -l $1 | awk '{print $1}') results..."
}

# Custom searches
echo "Searching /var/www/html/review.rdoproject.org..." | log
find "/var/www/html/review.rdoproject.org" -mindepth 5 -maxdepth 7 -type d -mtime +"${RETENTION}" >>$LOGFILE
result_count $LOGFILE | log
find "/var/www/html/review.rdoproject.org/openstack-periodic/" -mindepth 1 -maxdepth 2 -type d -mtime "+${RETENTION}" >>$LOGFILE
result_count $LOGFILE | log
find "/var/www/html/review.rdoproject.org/openstack-periodic-24hr/" -mindepth 1 -maxdepth 2 -type d -mtime "+${RETENTION}" >>$LOGFILE
result_count $LOGFILE | log

echo "Searching /var/www/html/ci.centos.org..." | log
find "/var/www/html/ci.centos.org" -maxdepth 2 -type d -mtime "+${RETENTION}" >>$LOGFILE
result_count $LOGFILE | log

echo "Searching /var/www/html/thirdparty..." | log
find "/var/www/html/thirdparty" -maxdepth 1 -type d -mtime "+${RETENTION}" >>$LOGFILE
result_count $LOGFILE | log

echo "Starting deletion..." | log
count=0
for dir in $(cat $LOGFILE |sort |uniq)
do
    # rm -rf $dir
    count=$(($count+1))
    if (( $count % 1000 == 0 )); then
        echo "${count} directories pruned..." | log
    fi
done

echo "Prune run ended." | log
echo "Log file: ${LOGFILE}" | log

df -h | log
df -i | log
