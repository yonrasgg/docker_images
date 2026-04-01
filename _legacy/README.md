# Legacy Images (Deprecated)

> **These images are unmaintained and not part of the hardened media stack.**
> They are preserved for reference only. Do NOT use them in production.

The images in this directory were early experiments and do not follow the
security practices applied to the main images (multi-stage builds, non-root
execution, vulnerability scanning, signing, etc.).

If you need any of these services, we recommend using established community
images or building your own following the patterns in the main repository.

## Contents

| Directory | Original Purpose |
|-----------|-----------------|
| `ftp-server/` | vsftpd FTP server (Alpine) |
| `heimdall-docker/` | Heimdall application dashboard |
| `iptables-docker/` | iptables firewall rules |
| `nginx-docker/` | Nginx + ModSecurity WAF |
| `puppet/` | Puppet Server |
| `wireguard-docker/` | WireGuard VPN |
