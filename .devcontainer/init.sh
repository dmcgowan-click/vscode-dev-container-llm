#!/bin/bash

# Use sudo if not running as root
sudoIf() { if [ "$(id -u)" -ne 0 ]; then sudo "$@"; else "$@"; fi }

# This black magic ensures the ubuntu user has permissions to the host dockers group ID. This must be done on startup
SOCKET_GID=$(stat -c '%g' /var/run/docker.sock) 
if [ "" != '0' ]; then
    if [ "$(cat /etc/group | grep :${SOCKET_GID}:)" = '' ]; then sudoIf groupadd --gid ${SOCKET_GID} docker-host; fi 
    if [ "$(id ubuntu | grep -E "groups=.*(=|,)${SOCKET_GID}\(")" = '' ]; then sudoIf usermod -aG ${SOCKET_GID} ubuntu; fi
fi
exec "$@"

# Start supervisord (dockers alternative to systemd)
sudoIf supervisord -c /etc/supervisord.conf
exec "$@"
