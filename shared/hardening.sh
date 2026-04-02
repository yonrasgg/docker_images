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

# --- Filesystem cleanup: remove unnecessary data from final image ---
echo "[hardening] Removing documentation, man pages, and locale data..."
# Preserve /usr/share/common-licenses and per-package copyright files
# for license-compliance (GPL/LGPL components require notice distribution)
find /usr/share/doc -mindepth 1 -maxdepth 1 -type d -exec sh -c \
  'for d; do find "$d" -not -name copyright -delete 2>/dev/null; done' _ {} + 2>/dev/null || true
rm -rf /usr/share/man/* \
       /usr/share/info/* \
       /usr/share/lintian/* \
       /usr/share/linda/* \
       /usr/share/groff/* \
       /usr/share/gcc/* \
       /usr/share/pixmaps/* \
       /usr/share/icons/* \
       /usr/share/locale/* \
       /usr/share/i18n/* \
       /usr/share/zoneinfo-icu/* \
       /usr/share/bug/* \
       2>/dev/null || true

echo "[hardening] Removing log files and caches..."
rm -rf /var/log/* /var/cache/* /var/tmp/* 2>/dev/null || true

echo "[hardening] Removing dpkg/apt package management metadata..."
rm -rf /var/lib/dpkg/info/*.list \
       /var/lib/dpkg/info/*.md5sums \
       /var/lib/dpkg/info/*.conffiles \
       /var/lib/dpkg/info/*.postinst \
       /var/lib/dpkg/info/*.preinst \
       /var/lib/dpkg/info/*.postrm \
       /var/lib/dpkg/info/*.prerm \
       /var/lib/dpkg/info/*.triggers \
       2>/dev/null || true

echo "[hardening] Removing shell history and profile files..."
rm -f /root/.bash_history /root/.bashrc /root/.profile 2>/dev/null || true

echo "[hardening] Done."
