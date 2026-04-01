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

# --- Fix ownership (volumes only) ---
chown media:media /config /downloads /incomplete-downloads
chmod 0750 /config

# --- Configure URL base for reverse proxy ---
SAB_INI="/config/sabnzbd.ini"
if [ -f "$SAB_INI" ]; then
    # Set url_base for path-based reverse proxy
    if grep -q '^url_base' "$SAB_INI"; then
        sed -i 's|^url_base.*|url_base = /sabnzbd|' "$SAB_INI"
    fi
fi

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
exec gosu media "$@"
