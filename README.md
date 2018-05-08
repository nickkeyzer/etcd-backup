# etcd-backup
A simple shell script for backing up etcd v2 and v3 datastores

## References
https://coreos.com/etcd/docs/latest/op-guide/recovery.html


## Requirements
This script requires `systemd-cat` to write log entries to the journal. 

- CentOS 7+ (_tested, working_)
- Ubuntu 15.04+ (_not tested, should work_)

## Useage
This script is expected to run on the server that runs etcd. Take note of installations using cert based authentication, this will effect the way the endpoints are referenced. Since this is expected to run locally on each etcd member in the cluster, the script defaults to `ENDPOINTS=https://localhost:2379`

Take note of the default data location (`ETCD_DATA_DIR`) and backup location (`ETCD_BACKUP_PREFIX`). These can be change by modifying the variables at the top of the shell script. 

In order to run this script, you must set an `etcd API version` and an `interval`. This can be done with the following options:
```
 --etcdv2         Sets etcd backup version to etcdv2 API. This is required if you have mixed v2/v3 data.

 --etcdv3         Sets etcd backup version to etcdv3 API. This will not include v2 data.

 --hourly         Sets the backup location to the hourly directory.

 --daily          Sets the backup location to the daily directory.
```

Kubernetes 1.6+ uses etcd v3 by default, however some plugins may use etcd v2. In this case, we're required to use the etcd v2 backup function since it will contain both v2 and v3 data.

## Installation
1. Place `etcd_backup.sh` script in `/opt/scripts/`
2. Create crontab entry for root

```bash
# Hourly etcd backups
0 * * * * sh /opt/scripts/etcd_backup.sh --etcdv3 --hourly
# Daily etcd backups
0 0 * * * sh /opt/scripts/etcd_backup.sh --etcdv3 --daily
# Keep last 6 hourly etcd backups, delete the rest
5 * * * * cd /var/lib/etcd/backups/hourly/; ls -tp | tail -n +7 | xargs -d '\n' -r rm -r --
# Keep last 7 daily etcd backups, delete the rest
5 * * * * cd /var/lib/etcd/backups/daily/; ls -tp | tail -n +8 | xargs -d '\n' -r rm -r --
```

## Logging
This script will write to the journal on systemd servers. You can see this by filtering the journal for the specific identifier:

```bash
$ journalctl -t etcd_backup
-- Logs begin at Wed 2018-02-14 18:15:06 CST, end at Tue 2018-02-27 10:10:38 CST. --
Feb 27 10:02:29 test-kube-master1.lucid.local etcd_backup[92811]: etcdv2 backup completed successfully.
```

## TODO

## Change log

### 0.1.0
- Initial commit
- Licensed