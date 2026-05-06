#!/bin/sh
set -eu

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-0022}

# --- Validate numeric IDs ---
case "${PUID}${PGID}" in
    *[!0-9]*)
        echo "ERROR: PUID and PGID must be numeric." >&2
        exit 1
        ;;
esac

# --- Adjust user/group IDs ---
if [ "$PGID" != "1000" ]; then
    sed -i "s/^media:x:1000:/media:x:${PGID}:/" /etc/group
    sed -i "s/^\(media:x:[0-9]*\):1000:/\1:${PGID}:/" /etc/passwd
fi
if [ "$PUID" != "1000" ]; then
    sed -i "s/^media:x:1000:/media:x:${PUID}:/" /etc/passwd
fi

# --- Fix ownership (volume only) ---
chown media:media /data

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
exec su-exec media "$@"
