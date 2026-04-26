#!/bin/sh
set -eu

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-0022}
DOCKER_GID=${DOCKER_GID:-}

# --- Adjust user/group IDs ---
if [ "$PGID" != "1000" ]; then
    sed -i "s/^media:x:1000:/media:x:${PGID}:/" /etc/group
    sed -i "s/^\(media:x:[0-9]*\):1000:/\1:${PGID}:/" /etc/passwd
fi
if [ "$PUID" != "1000" ]; then
    sed -i "s/^media:x:1000:/media:x:${PUID}:/" /etc/passwd
fi

# --- Optional Docker socket group mapping ---
# Runtime images strip addgroup/usermod, so modify /etc/group directly when
# DOCKER_GID is provided (common for /var/run/docker.sock group access).
if [ -n "$DOCKER_GID" ]; then
    case "$DOCKER_GID" in
        *[!0-9]*)
            echo "DOCKER_GID must be numeric: ${DOCKER_GID}" >&2
            exit 1
            ;;
    esac

    existing_gid_group="$(awk -F: -v gid="$DOCKER_GID" '$3==gid {print $1; exit}' /etc/group || true)"
    if [ -n "$existing_gid_group" ] && [ "$existing_gid_group" != "docker" ]; then
        awk -F: -v grp="$existing_gid_group" '
            BEGIN { OFS=":" }
            $1 == grp {
                if ($4 == "") {
                    $4 = "media"
                } else if ($4 !~ /(^|,)media(,|$)/) {
                    $4 = $4 ",media"
                }
            }
            { print }
        ' /etc/group > /tmp/group && mv /tmp/group /etc/group
    elif grep -q '^docker:' /etc/group; then
        sed -i "s/^docker:[^:]*:[0-9]*:.*/docker:x:${DOCKER_GID}:media/" /etc/group
    else
        echo "docker:x:${DOCKER_GID}:media" >> /etc/group
    fi
fi

# --- Fix ownership (volume only) ---
chown media:media /data

# --- Set umask ---
umask "$UMASK"

# --- Drop privileges and exec ---
cd /data
exec su-exec media "$@"
