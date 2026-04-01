# Hardened Docker Images

[![Build and Push](https://github.com/yonrasgg/docker_images/actions/workflows/build-push.yml/badge.svg)](https://github.com/yonrasgg/docker_images/actions/workflows/build-push.yml)
[![Security Scan](https://github.com/yonrasgg/docker_images/actions/workflows/security-scan.yml/badge.svg)](https://github.com/yonrasgg/docker_images/actions/workflows/security-scan.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/yonrasgg/docker_images/badge)](https://securityscorecards.dev/viewer/?uri=github.com/yonrasgg/docker_images)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Production-grade, security-hardened Docker images for a self-hosted media server stack.

Every image is built with multi-stage builds, runs as a non-root user, is scanned for vulnerabilities before publishing, **cryptographically signed with [Cosign](https://docs.sigstore.dev/cosign/overview/)**, and ships with an **SBOM** and **SLSA provenance** attestation.

## Images

| Image | Port | Description | Pull |
|-------|------|-------------|------|
| **sonarr** | 8989 | TV series PVR for Usenet/BitTorrent | `docker pull ghcr.io/yonrasgg/sonarr:latest` |
| **radarr** | 7878 | Movie collection manager | `docker pull ghcr.io/yonrasgg/radarr:latest` |
| **sabnzbd** | 8080 | Usenet binary downloader | `docker pull ghcr.io/yonrasgg/sabnzbd:latest` |
| **jackett** | 9117 | Indexer proxy/aggregator | `docker pull ghcr.io/yonrasgg/jackett:latest` |
| **plex** | 32400 | Media server with HW transcoding | `docker pull ghcr.io/yonrasgg/plex:latest` |

## Supply Chain Security

> **Trust, but verify.** Every image in this repository can be independently verified before deployment.

### Verify Image Signatures

All images are signed with [Sigstore Cosign](https://docs.sigstore.dev/cosign/overview/) using keyless OIDC signing tied to the GitHub Actions workflow identity. No private keys are stored.

```bash
# Install Cosign: https://docs.sigstore.dev/cosign/system_config/installation/

# Verify any image
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp "https://github.com/yonrasgg/docker_images/" \
  ghcr.io/yonrasgg/sonarr:latest
```

### Inspect the SBOM

Every image has an SPDX Software Bill of Materials attached as a Cosign attestation:

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp "https://github.com/yonrasgg/docker_images/" \
  ghcr.io/yonrasgg/sonarr:latest | jq -r '.payload' | base64 -d | jq .
```

### SLSA Provenance

Build provenance is embedded in every image (BuildKit `provenance: mode=max`):

```bash
docker buildx imagetools inspect ghcr.io/yonrasgg/sonarr:latest --format '{{json .Provenance}}'
```

## Security Hardening

Every image applies these security controls:

- **Multi-stage builds** — build tools never ship in runtime images
- **Non-root execution** — services run as unprivileged `media` user via `gosu`
- **SUID/SGID removal** — all unnecessary privileged binaries are stripped
- **Minimal packages** — only runtime dependencies installed
- **Health checks** — built-in container health monitoring
- **`tini` PID 1** — proper signal handling and zombie reaping
- **OCI labels** — full provenance metadata on every image
- **No embedded secrets** — configuration via env vars and volumes only
- **Multi-arch** — `linux/amd64` + `linux/arm64`
- **Reverse proxy ready** — URL base paths auto-configured for Caddy/Nginx
- **Capability drop** — designed for `cap_drop: ALL` with minimal adds
- **`.dockerignore`** — build context excludes secrets, docs, and legacy files

## Quick Start

```bash
# Pull a single image
docker pull ghcr.io/yonrasgg/sonarr:latest

# Verify the signature before running
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp "https://github.com/yonrasgg/docker_images/" \
  ghcr.io/yonrasgg/sonarr:latest

# Run with maximum hardening
docker run -d \
  --name sonarr \
  -e PUID=1000 -e PGID=1000 \
  -e TZ=America/Costa_Rica \
  -v ./config/sonarr:/config \
  -v ./downloads:/downloads \
  -v ./media/tv:/tv \
  --read-only \
  --tmpfs /tmp:size=256m,noexec,nosuid \
  --tmpfs /run:size=16m,noexec,nosuid \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --cap-add SETUID --cap-add SETGID --cap-add CHOWN \
  ghcr.io/yonrasgg/sonarr:latest
```

For the full media stack with TLS, VPN access, and nftables firewall, see the [HomeServer](https://github.com/yonrasgg/HomeServer) companion repository.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for the service process |
| `PGID` | `1000` | Group ID for the service process |
| `TZ` | `UTC` | Timezone (e.g., `America/Costa_Rica`) |
| `UMASK` | `0022` | File creation mask |
| `PLEX_CLAIM` | *(empty)* | Plex claim token (plex image only, first run) |

## CI/CD Pipeline

```
Push to main ──► Hadolint + ShellCheck ──► Build (amd64 + arm64)
                                            │
                                            ├──► Trivy scan (gate: 0 CRITICAL/HIGH)
                                            │
                                            ├──► Push to ghcr.io
                                            │
                                            ├──► Cosign keyless sign (OIDC)
                                            │
                                            ├──► Syft SBOM generation + attestation
                                            │
                                            └──► SLSA provenance (BuildKit)

Weekly cron ────► Rebuild all images (picks up base image patches)

Nightly cron ───► Grype scan (all published images)

On-demand ──────► OpenSSF Scorecard assessment
```

- **Build**: Multi-arch via `docker buildx` on GitHub Actions
- **Scan**: Trivy (per-build gate) + Grype (nightly) + Hadolint + ShellCheck
- **Sign**: Cosign keyless signing via Sigstore OIDC
- **Attest**: SBOM (Syft/SPDX) + SLSA provenance (BuildKit)
- **Push**: Tagged with `latest`, `YYYY.MM.DD`, and short SHA
- **Monitor**: Dependabot watches base images, dependencies, and Actions weekly
- **Assess**: OpenSSF Scorecard runs weekly for supply chain health
- **Pinned**: All CI/CD actions are pinned by commit SHA

## Architecture Decision: Debian over Alpine

The media stack images use `debian:bookworm-slim` instead of Alpine because:

- Sonarr, Radarr, and Jackett are .NET applications that depend on `libicu` and `glibc` — Alpine uses `musl`, which causes runtime incompatibilities
- Plex Media Server distributes official `.deb` packages only
- `bookworm-slim` provides a minimal footprint (~80 MB) with broad compatibility
- Security scanning coverage for Debian packages is more comprehensive in Trivy/Grype

SABnzbd (Python-based) could theoretically run on Alpine, but using a consistent base across the stack simplifies maintenance and security patching.

## Repository Structure

```
├── sonarr/          # Sonarr Dockerfile + entrypoint
├── radarr/          # Radarr Dockerfile + entrypoint
├── sabnzbd/         # SABnzbd Dockerfile + entrypoint
├── jackett/         # Jackett Dockerfile + entrypoint
├── plex/            # Plex Dockerfile + entrypoint
├── shared/          # Common hardening scripts
├── .github/         # CI/CD workflows, Dependabot, Scorecard
├── SECURITY.md      # Security policy, vulnerability reporting, verification
├── CONTRIBUTING.md  # Development and contribution guide
└── CODEOWNERS       # Code ownership and review requirements
```

## License

[MIT](LICENSE) — Geovanny Alpizar

### Legacy Images

The following images are from earlier versions of this repository and are no longer actively maintained:

- `ftp-server/` — VSFTPD server
- `heimdall-docker/` — Application dashboard
- `iptables-docker/` — iptables firewall
- `nginx-docker/` — Nginx with ModSecurity WAF
- `puppet/` — Puppet Server
- `wireguard-docker/` — WireGuard VPN

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, coding standards, and the PR process.

## Security

See [SECURITY.md](SECURITY.md) for our security policy and how to report vulnerabilities.

## License

[MIT](LICENSE)
