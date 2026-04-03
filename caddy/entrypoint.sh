#!/bin/sh
set -eu

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-0022}

# --- Adjust user/group IDs ---
if [ "$PGID" != "1000" ]; then
    sed -i "s/^media:x:1000:/media:x:${PGID}:/" /etc/group
    sed -i "s/^\(media:x:[0-9]*\):1000:/\1:${PGID}:/" /etc/passwd
fi
if [ "$PUID" != "1000" ]; then
    sed -i "s/^media:x:1000:/media:x:${PUID}:/" /etc/passwd
fi

# --- Fix ownership (volumes only) ---
chown media:media /data /config /etc/caddy

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
exec su-exec media "$@"
