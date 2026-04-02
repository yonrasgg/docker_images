#!/bin/sh
# =============================================================================
# Final Image Stripping Script
# Removes package managers, user-management tools, and unnecessary binaries
# to prevent runtime tampering. Must run AFTER user creation.
# Supports both Debian (apt/dpkg) and Alpine (apk) based images.
# https://github.com/yonrasgg/docker_images
# =============================================================================
set -eu

# Detect OS family
if [ -f /etc/alpine-release ]; then
    OS_FAMILY="alpine"
else
    OS_FAMILY="debian"
fi

echo "[strip] Detected OS: ${OS_FAMILY}"

echo "[strip] Removing package manager..."
if [ "$OS_FAMILY" = "alpine" ]; then
    # Remove apk binary, config, and caches but keep /lib/apk/db/installed
    # so Trivy/Grype/Syft can detect installed OS packages and generate SBOMs.
    rm -rf /sbin/apk /etc/apk /usr/share/apk \
           /var/cache/apk
else
    # Preserve /var/lib/dpkg/status so Trivy/Grype can detect OS packages.
    # Remove only the binaries, libraries, and config — not the package database.
    rm -rf /usr/bin/apt* /usr/bin/dpkg* /usr/lib/apt /usr/lib/dpkg \
           /etc/apt /var/lib/apt \
           /var/lib/dpkg/info /var/lib/dpkg/updates \
           /var/lib/dpkg/alternatives /var/lib/dpkg/triggers \
           /var/lib/dpkg/available
fi

echo "[strip] Removing file-search utilities..."
rm -rf /usr/bin/find /usr/bin/locate /usr/bin/xargs

echo "[strip] Removing user-management tools..."
if [ "$OS_FAMILY" = "alpine" ]; then
    # Alpine uses BusyBox symlinks; remove standalone shadow tools if present
    rm -rf /usr/sbin/addgroup /usr/sbin/adduser /usr/sbin/deluser /usr/sbin/delgroup \
           /usr/sbin/groupadd /usr/sbin/useradd /usr/sbin/newusers \
           /usr/bin/passwd
else
    rm -rf /usr/bin/passwd /usr/sbin/adduser /usr/sbin/deluser \
           /usr/sbin/groupadd /usr/sbin/useradd /usr/sbin/newusers
fi

echo "[strip] Removing messaging and unnecessary shells/interpreters..."
rm -rf /usr/bin/wall /usr/bin/write \
       /usr/share/perl* /usr/share/zsh

# Python-specific: remove pip if present (not needed at runtime)
if [ -d /usr/local/lib/python3.13 ]; then
    echo "[strip] Removing pip from Python runtime..."
    rm -rf /usr/local/lib/python3.13/site-packages/pip* \
           /usr/local/bin/pip*
fi

echo "[strip] Done."
