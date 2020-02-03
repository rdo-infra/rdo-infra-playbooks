#!/bin/bash

set -x
set -e

SRC_HOST=${SRC_HOST:-''}
SRC_HOST_USER=${SRC_HOST_USER:-'centos'}
SYNC_PATH="/var/www/html/images"
SSH_SYNC_KEY_PATH=${SSH_SYNC_KEY_PATH:-"$HOME/.ssh/id_rsa"}
LOCK_PATH=/tmp/$(basename "$0")
LOG_FILE="$HOME/sync_images.log"

if [ -f "${LOCK_PATH}" ]; then
    echo "There is another $(basename "$0") script running" | tee -a $LOG_FILE
    exit 1
fi

if [ -z "${SRC_HOST}" ]; then
    echo "No SRC_HOST provided. Please export SRC_HOST=" | tee -a $LOG_FILE
    exit 1
fi

echo "Creating lock file $(date '+%d/%m/%Y %H:%M:%S')" | tee -a $LOG_FILE
touch "$LOCK_PATH"

function remove_lock {
    rm -f "${LOCK_PATH}"
}

trap remove_lock EXIT

echo "Starting sync $(date '+%d/%m/%Y %H:%M:%S') ${SRC_HOST_USER}@${SRC_HOST}:${SYNC_PATH}" | tee -a $LOG_FILE
rsync -e "ssh -i ${SSH_SYNC_KEY_PATH}" -avz --progress --delete \
    "${SRC_HOST_USER}@${SRC_HOST}:${SYNC_PATH}"'/'  "${SYNC_PATH}" | tee -a $LOG_FILE
