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
chown media:media /config /downloads /watch
chmod 0750 /config

# --- Generate default settings.json if missing ---
SETTINGS="/config/settings.json"
if [ ! -f "$SETTINGS" ]; then
    cat > "$SETTINGS" <<'EOF'
{
    "download-dir": "/downloads",
    "incomplete-dir": "/downloads/incomplete",
    "incomplete-dir-enabled": true,
    "watch-dir": "/watch",
    "watch-dir-enabled": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-port": 9091,
    "rpc-whitelist-enabled": false,
    "rpc-host-whitelist-enabled": false,
    "rpc-authentication-required": false,
    "peer-port": 51413,
    "peer-port-random-on-start": false,
    "port-forwarding-enabled": false,
    "umask": 18
}
EOF
    chown media:media "$SETTINGS"
fi

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
exec gosu media "$@"
