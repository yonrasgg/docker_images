#!/bin/sh
set -eu

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-0022}

# --- Adjust user/group IDs ---
if [ "$PGID" != "1000" ]; then
    sed -i "s/^media:x:1000:/media:x:${PGID}:/" /etc/group
    # Also update the GID field in /etc/passwd so su-exec applies the new group
    sed -i "s/^\(media:x:[0-9]*\):1000:/\1:${PGID}:/" /etc/passwd
fi
if [ "$PUID" != "1000" ]; then
    sed -i "s/^media:x:1000:/media:x:${PUID}:/" /etc/passwd
fi

# --- Fix ownership (volumes only) ---
chown media:media /data

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
cd /data
exec su-exec media "$@"
