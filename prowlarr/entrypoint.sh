#!/bin/bash
set -euo pipefail

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-0022}

# --- Adjust user/group IDs ---
if [ "$PGID" != "1000" ]; then
    groupmod -o -g "$PGID" media
fi
if [ "$PUID" != "1000" ]; then
    usermod -o -u "$PUID" media
fi

# --- Fix ownership (volumes only, not application) ---
chown media:media /config
chmod 0750 /config

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
exec gosu media "$@"
