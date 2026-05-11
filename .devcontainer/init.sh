#!/bin/bash

# Use sudo if not running as root
sudoIf() { if [ "$(id -u)" -ne 0 ]; then sudo "$@"; else "$@"; fi }

# This black magic ensures the ubuntu user has permissions to the host dockers group ID. This must be done on startup
SOCKET_GID=$(stat -c '%g' /var/run/docker.sock) 
if [ "" != '0' ]; then
    if [ "$(cat /etc/group | grep :${SOCKET_GID}:)" = '' ]; then sudoIf groupadd --gid ${SOCKET_GID} docker-host; fi 
    if [ "$(id ubuntu | grep -E "groups=.*(=|,)${SOCKET_GID}\(")" = '' ]; then sudoIf usermod -aG ${SOCKET_GID} ubuntu; fi
fi

# Remove the credsStore injected by VS Code Dev Containers, which proxies to the
# host's credential helper (e.g. Windows) and breaks docker push inside the container.
DOCKER_CONFIG="$HOME/.docker/config.json"
if [ -f "$DOCKER_CONFIG" ] && command -v jq > /dev/null 2>&1; then
    if jq -e '.credsStore' "$DOCKER_CONFIG" > /dev/null 2>&1; then
        jq 'del(.credsStore)' "$DOCKER_CONFIG" > "$DOCKER_CONFIG.tmp" && mv "$DOCKER_CONFIG.tmp" "$DOCKER_CONFIG"
    fi
fi

exec "$@"

# Start supervisord (dockers alternative to systemd)
# NOTE: Currently not working as expected, so also called within the devcontainer.json as a postcommand
sudoIf supervisord -c /etc/supervisord.conf
exec "$@"
