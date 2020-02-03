#!/bin/bash

set -x
set -e

SRC_HOST=${SRC_HOST:-''}
SYNC_PATH="/var/www/html/images"
SSH_SYNC_KEY_PATH=${SSH_SYNC_KEY_PATH:-$1}
LOCK_PATH=/tmp/$(basename "$0")

if [ -f "${LOCK_PATH}" ]; then
    echo "There is another $(basename "$0") script running"
    exit 1
fi

if [ -z "${SRC_HOST}" ]; then
    echo "No SRC_HOST provided. Please export SRC_HOST="
    exit 1
fi

if [ -z "${SSH_SYNC_KEY_PATH}" ]; then
    SSH_SYNC_KEY_PATH="$HOME/.ssh/tmp-sync-key-$(date '+%Y%m%d-%H%M%S')"
fi

echo "Creating lock file"
touch "$LOCK_PATH"

function remove_keys {
    if echo "$SSH_SYNC_KEY_PATH" | grep -q "tmp-sync-key-[0-9]\{8\}-[0-9]\{6\}"; then
        rm "${SSH_SYNC_KEY_PATH}"
        rm "${SSH_SYNC_KEY_PATH}.pub"
    fi
}

function remove_lock {
    rm -f "${LOCK_PATH}"
}

trap remove_keys EXIT
trap remove_lock EXIT

if echo "$SSH_SYNC_KEY_PATH" | grep -q "tmp-sync-key-[0-9]\{8\}-[0-9]\{6\}"; then
    ssh-keygen -t ed25519 -f "${SSH_SYNC_KEY_PATH}" -N ""
    cat "${SSH_SYNC_KEY_PATH}.pub"

    echo -e " \n\nPlease copy the key and put it on dest host in authorized_keys \n\n"
    read -r "Did you done it?" yn
    case $yn in
        [Yy]* ) echo "continue" ;;
        * ) echo "Removing keys. Do it one more time"; remove_keys; exit 1;;
    esac
fi


ssh-keyscan -t ed25519 "${SRC_HOST}" | tee -a "$HOME/.ssh/known_hosts"

sudo rsync -e "ssh -i ${SSH_SYNC_KEY_PATH}" -avz --progress --delete \
           "centos@${SRC_HOST}:${SYNC_PATH}"'/'  "${SYNC_PATH}"
