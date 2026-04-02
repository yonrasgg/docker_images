#!/bin/sh
# =============================================================================
# Final Image Stripping Script
# Removes package managers, user-management tools, and unnecessary binaries
# to prevent runtime tampering. Must run AFTER user creation.
# https://github.com/yonrasgg/docker_images
# =============================================================================
set -eu

echo "[strip] Removing package manager (apt/dpkg)..."
rm -rf /usr/bin/apt* /usr/bin/dpkg* /usr/lib/apt /usr/lib/dpkg \
       /etc/apt /var/lib/apt /var/lib/dpkg

echo "[strip] Removing file-search utilities..."
rm -rf /usr/bin/find /usr/bin/locate /usr/bin/xargs

echo "[strip] Removing user-management tools..."
rm -rf /usr/bin/passwd /usr/sbin/adduser /usr/sbin/deluser \
       /usr/sbin/groupadd /usr/sbin/useradd /usr/sbin/newusers

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
