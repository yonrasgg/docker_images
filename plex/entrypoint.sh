#!/bin/bash
set -euo pipefail

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-0022}
PLEX_CLAIM=${PLEX_CLAIM:-}

# --- Adjust user/group IDs ---
if [ "$PGID" != "1000" ]; then
    groupmod -o -g "$PGID" media
fi
if [ "$PUID" != "1000" ]; then
    usermod -o -u "$PUID" media
fi

# Ensure video/render group membership for HW transcoding
usermod -aG video,render media 2>/dev/null || true

# --- Fix ownership (volumes only, not application binaries) ---
chown media:media /config /transcode
chmod 0750 /config
# Media is read-only, no chown needed

# --- Set Plex environment ---
export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="/config"
export PLEX_MEDIA_SERVER_HOME="/opt/plex"
export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
export PLEX_MEDIA_SERVER_TMPDIR="/transcode"
export LD_LIBRARY_PATH="/opt/plex:${LD_LIBRARY_PATH:-}"
export PATH="/opt/plex:${PATH}"

# --- Enforce secure network preferences ---
PREFS_DIR="/config/Plex Media Server"
PREFS_FILE="$PREFS_DIR/Preferences.xml"
if [ -f "$PREFS_FILE" ]; then
    # Force secure connections (1 = preferred, 2 = required)
    if command -v xmlstarlet &>/dev/null; then
        xmlstarlet ed -L \
            -u '//Preferences/@secureConnections' -v '1' \
            "$PREFS_FILE" 2>/dev/null || true
    fi
fi

# --- Handle initial Plex claim token ---
if [ -n "$PLEX_CLAIM" ] && [ ! -f "$PREFS_FILE" ]; then
    echo "[plex] First run — claim token will be applied during startup."
    mkdir -p "$PREFS_DIR"
    chown media:media "$PREFS_DIR"
fi

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
exec gosu media "$@"
