#!/usr/bin/bash


sed -i -e "s/FQDN/$SERVER_NAME/g" /etc/haproxy/haproxy.cfg

sed -i -e "s/LIVESERVER/$LIVE_PORT_80_TCP_ADDR/g" /etc/haproxy/haproxy.cfg

sed -i -e "s/BACKUPSERVER/$BACKUP_PORT_80_TCP_ADDR/g" /etc/haproxy/haproxy.cfg


command="/usr/bin/supervisord"
echo [DOCKER INFO] Executing: $command
$command