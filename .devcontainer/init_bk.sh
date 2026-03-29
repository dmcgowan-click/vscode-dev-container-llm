#!/bin/bash
set -e  # Exit on error

# Use sudo if not running as root
sudoIf() { if [ "$(id -u)" -ne 0 ]; then sudo "$@"; else "$@"; fi }

# This ensures the ubuntu user has permissions to the host docker's group ID. This must be done on startup
SOCKET_GID=$(stat -c '%g' /var/run/docker.sock)
if [ "${SOCKET_GID}" != '0' ]; then
    sudoIf groupadd --gid "${SOCKET_GID}" docker-host 2>/dev/null || true
    sudoIf usermod -aG "${SOCKET_GID}" ubuntu 2>/dev/null || true
fi

# Start supervisord (docker's alternative to systemd)
exec sudoIf supervisord -c /etc/supervisord.conf
