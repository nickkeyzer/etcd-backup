#!/bin/bash

# Copyright 2018 Nicholas Keyzer
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Positional Parameters

while [[ "$1" != "" ]]; do
    case $1 in
        --etcdv2)
            ETCD_VERSION=2
            ;;
        --etcdv3)
            ETCD_VERSION=3
            ;;
        --hourly)
            ETCD_BACKUP_INTERVAL=hourly
            ;;
        --daily)
            ETCD_BACKUP_INTERVAL=daily
            ;;
        -h | --help)
            echo "Available options for etcd_backup script:"
            echo -e "\n --etcdv2         Sets etcd backup version to etcdv2 API. This is required if you have mixed v2/v3 data."
            echo -e "\n --etcdv3         Sets etcd backup version to etcdv3 API. This will not include v2 data."
            echo -e "\n --hourly         Sets the backup location to the hourly directory."
            echo -e "\n --daily          Sets the backup location to the daily directory."
            echo -e "\n -h | --help      Shows this help output."
            exit
            ;;
        *)
            echo "invalid option specified"
            exit 1
    esac
    shift
done

## Variables

ETCD_DATA_DIR=/var/lib/etcd #only required for etcdv3
ETCD_BACKUP_PREFIX=/var/lib/etcd/backups/$ETCD_BACKUP_INTERVAL
ETCD_BACKUP_DIRECTORY=$ETCD_BACKUP_PREFIX/etcd-$(date +"%F")_$(date +"%T")
ENDPOINTS=https://localhost:2379

## Functions

backup_etcdv2() {
    # create the backup directory if it doesn't exist
    [[ -d $ETCD_BACKUP_DIRECTORY ]] || mkdir -p $ETCD_BACKUP_DIRECTORY
    
    # backup etcd v2 data
    export ETCDCTL_API=2
    /usr/local/bin/etcdctl backup \
        --data-dir $ETCD_DATA_DIR \
        --backup-dir $ETCD_BACKUP_DIRECTORY
}

backup_etcdv3() {
    # create the backup directory if it doesn't exist
    [[ -d $ETCD_BACKUP_DIRECTORY ]] || mkdir -p $ETCD_BACKUP_DIRECTORY
    
    # backup etcd v3 data
    export ETCDCTL_API=3
    /usr/local/bin/etcdctl \
        --endpoints=$ENDPOINTS \
        snapshot save $ETCD_BACKUP_DIRECTORY/snapshot.db
}

backup_logger() {
    if [[ $? -ne 0 ]]; then
        echo "etcdv$ETCD_VERSION $ETCD_BACKUP_INTERVAL backup failed on $HOSTNAME." | systemd-cat -t etcd_backup -p err
    else
        echo "etcdv$ETCD_VERSION $ETCD_BACKUP_INTERVAL backup completed successfully." | systemd-cat -t etcd_backup -p info
    fi
}

# check if backup interval is set
if [[ -z "$ETCD_BACKUP_INTERVAL" ]]; then
    echo "You must set a backup interval. Use either the --hourly or --daily option."
    echo "See -h | --help for more information."
    exit 1
fi

# run backups and log results
if [[ "$ETCD_VERSION" = "2" ]]; then
    backup_etcdv2
    backup_logger
elif [[ "$ETCD_VERSION" = "3" ]]; then
    backup_etcdv3
    backup_logger
else
    echo "You must set an etcd version. Use either the --etcdv2 or --etcdv3 option."
    echo "See -h | --help for more information."
    exit 1
fi