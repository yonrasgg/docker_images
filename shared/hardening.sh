#!/bin/sh
# =============================================================================
# Container Hardening Script
# Applied during image build to reduce attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================
set -eu

echo "[hardening] Removing SUID/SGID bits (except gosu)..."
find / -perm /6000 -type f ! -name gosu -exec chmod a-s {} + 2>/dev/null || true

echo "[hardening] Removing crontabs and scheduled tasks..."
rm -rf /var/spool/cron /etc/crontabs /etc/periodic 2>/dev/null || true

echo "[hardening] Removing init scripts..."
rm -rf /etc/init.d /lib/rc /etc/conf.d /etc/inittab /etc/runlevels /etc/rc.conf 2>/dev/null || true

echo "[hardening] Removing kernel tunables..."
rm -rf /etc/sysctl* /etc/modprobe.d /etc/modules /etc/mdev.conf 2>/dev/null || true

echo "[hardening] Removing fstab..."
rm -f /etc/fstab 2>/dev/null || true

echo "[hardening] Removing world-writable directories..."
find / -xdev -type d -perm /0002 -exec chmod o-w {} + 2>/dev/null || true

echo "[hardening] Removing unnecessary user accounts..."
for user in games news uucp proxy list; do
    deluser "$user" 2>/dev/null || true
done

echo "[hardening] Setting secure /tmp permissions..."
chmod 1777 /tmp 2>/dev/null || true

echo "[hardening] Done."
