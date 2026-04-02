#!/bin/sh
set -eu

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-0022}

# --- Adjust user/group IDs ---
if [ "$PGID" != "1000" ]; then
    sed -i "s/media:x:1000:/media:x:${PGID}:/" /etc/group
fi
if [ "$PUID" != "1000" ]; then
    sed -i "s/media:x:1000:1000/media:x:${PUID}:${PGID}/" /etc/passwd
fi

# --- Fix ownership (volumes only, not application) ---
chown media:media /app/user-data

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
cd /app
exec su-exec media "$@"
