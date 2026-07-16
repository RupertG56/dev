#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <0|1>"
    echo "  0 = stop services"
    echo "  1 = start services"
    exit 1
fi

SYSTEM_SERVICES=(
    mkvtoolnix
    nzb
    pihole
    plex
    samba
    traefik
)

USER_SERVICES=(
    factorio1
    factorio2
    factorio3
)

case "$1" in
    0)
        ACTION="stop"
        ;;
    1)
        ACTION="start"
        ;;
    *)
        echo "Invalid argument: $1"
        echo "Use 0 to stop or 1 to start."
        exit 1
        ;;
esac

echo "${ACTION^}ing system services..."
for svc in "${SYSTEM_SERVICES[@]}"; do
    sudo systemctl "$ACTION" "$svc"
done

echo "${ACTION^}ing user services..."
for svc in "${USER_SERVICES[@]}"; do
    systemctl --user "$ACTION" "$svc"
done

echo "Done."
