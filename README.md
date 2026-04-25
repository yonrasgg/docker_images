# Hardened Docker Images

[![CI Gate](https://github.com/yonrasgg/docker_images/actions/workflows/ci-gate.yml/badge.svg?branch=hardening)](https://github.com/yonrasgg/docker_images/actions/workflows/ci-gate.yml)
[![Publish](https://github.com/yonrasgg/docker_images/actions/workflows/build-push.yml/badge.svg)](https://github.com/yonrasgg/docker_images/actions/workflows/build-push.yml)
[![Nightly Scan](https://github.com/yonrasgg/docker_images/actions/workflows/security-scan.yml/badge.svg)](https://github.com/yonrasgg/docker_images/actions/workflows/security-scan.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/yonrasgg/docker_images/badge)](https://securityscorecards.dev/viewer/?uri=github.com/yonrasgg/docker_images)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Production-grade, security-hardened Docker images for a self-hosted media server stack.

Every image is built with multi-stage builds, runs as a non-root user, is scanned for vulnerabilities before publishing, **cryptographically signed with [Cosign](https://docs.sigstore.dev/cosign/overview/)**, and ships with an **SBOM** and **SLSA provenance** attestation.

## Images

| Image | Port | Description | Pull |
|-------|------|-------------|------|
| **sonarr** | 8989 | TV series PVR for Usenet/BitTorrent | `docker pull ghcr.io/yonrasgg/sonarr:latest` |
| **radarr** | 7878 | Movie collection manager | `docker pull ghcr.io/yonrasgg/radarr:latest` |
| **transmission** | 9091 | BitTorrent client with web UI | `docker pull ghcr.io/yonrasgg/transmission:latest` |
| **prowlarr** | 9696 | Indexer manager for Usenet/BitTorrent | `docker pull ghcr.io/yonrasgg/prowlarr:latest` |
| **plex** | 32400 | Media server with HW transcoding | `docker pull ghcr.io/yonrasgg/plex:latest` |
| **dashy** | 8080 | Self-hosted application dashboard | `docker pull ghcr.io/yonrasgg/dashy:latest` |
| **wireguard-ui** | 5000 | WireGuard VPN web management UI | `docker pull ghcr.io/yonrasgg/wireguard-ui:latest` |
| **syncthing** | 8384 | Continuous file synchronization | `docker pull ghcr.io/yonrasgg/syncthing:latest` |
| **caddy** | 80, 443 | Reverse proxy with automatic HTTPS | `docker pull ghcr.io/yonrasgg/caddy:latest` |

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
- **Non-root execution** — services run as unprivileged `media` user via `gosu` (Debian) or `su-exec` (Alpine)
- **SUID/SGID removal** — all unnecessary privileged binaries are stripped
- **Package manager removal** — `apt`/`dpkg` (Debian) and `apk` (Alpine) are stripped from final images
- **Minimal packages** — only runtime dependencies installed
- **Health checks** — built-in container health monitoring
- **`tini` PID 1** — proper signal handling and zombie reaping
- **OCI labels** — full provenance metadata on every image
- **No embedded secrets** — configuration via env vars and volumes only
- **Architecture** — `linux/amd64`
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

Images reach `ghcr.io` only after passing every gate. Development happens on the `hardening` branch; `main` is the release branch.

```
hardening branch ──► CI Gate workflow
                      │
                      ├─ Hadolint (Dockerfile lint)
                      ├─ ShellCheck (script lint)
                      ├─ Build (amd64, no push)
                      ├─ Trivy scan (CRITICAL/HIGH = fail)
                      └─ Smoke test (start container, verify healthcheck)
                      │
                      ▼
               All gates pass?
                 NO → fix on hardening, re-run
                 YES ↓
                      │
PR: hardening → main ─► CODEOWNER approval required
                      │
                      ▼
main branch ──────► Publish workflow
                      │
                      ├─ Final Trivy scan (belt-and-suspenders)
                      ├─ Build amd64 image
                      ├─ Push to ghcr.io (latest + YYYY.MM.DD + SHA)
                      ├─ Cosign keyless signing (OIDC)
                      ├─ Syft SBOM generation + attestation
                      └─ SLSA provenance (BuildKit)

Weekly cron ────────► Rebuild all images (picks up base image patches)
Nightly cron ───────► Grype scan (published images, fix-available HIGH/CRITICAL CVEs)
On-demand ──────────► OpenSSF Scorecard assessment
```

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **CI Gate** | Push to `hardening`, PR to `hardening` or `main` | Validate: lint, build, scan, smoke test |
| **Publish** | Push to `main`, weekly cron | Build, sign, attest, push to registry |
| **Nightly Scan** | Daily cron | Grype scan of published images for new HIGH/CRITICAL CVEs with fixes available |
| **Scorecard** | Push to `main`, weekly cron | OpenSSF supply chain health assessment |

- **Gate**: `✅ All CI Gates Passed` is required by branch protection before merge
- **Pinned**: All CI/CD actions are pinned by commit SHA
- **Monitor**: Renovate opens PRs against `hardening` for Docker base images, pinned app releases, and GitHub Actions

## Architecture Decisions

### Debian for Media Stack

The media stack images (Sonarr, Radarr, Prowlarr, Plex, Transmission) use `debian:bookworm-slim` because:

- Sonarr, Radarr, and Prowlarr are .NET applications that depend on `libicu` and `glibc` — Alpine uses `musl`, which causes runtime incompatibilities
- Plex Media Server distributes official `.deb` packages only
- Transmission is compiled from source (C/C++17) and links against Debian system libraries (libcurl, libevent, libminiupnpc, libnatpmp, libssl)
- `bookworm-slim` provides a minimal footprint (~80 MB) with broad compatibility
- Security scanning coverage for Debian packages is more comprehensive in Trivy/Grype

Transmission is compiled from source because Debian bookworm packages only v3.00 while the latest stable release is v4.1.1.

### Alpine for Dashy

Dashy uses `node:20-alpine` because:

- Dashy is a pure Node.js/Vue application with no native library dependencies
- Alpine's recommended base image is the official Dashy documentation choice
- Alpine produces significantly smaller images (~50 MB vs ~80 MB base)
- `su-exec` replaces `gosu` as the lightweight Alpine equivalent for privilege dropping
- `apk` is stripped post-build, same as `apt`/`dpkg` on Debian images

### Alpine for Go Applications

WireGuard UI, Syncthing, and Caddy use `alpine:3.21` because:

- All are statically-compiled Go binaries with zero native library dependencies
- WireGuard UI is compiled from source (`CGO_ENABLED=0`) in a Go builder stage
- Caddy is compiled from source via `xcaddy` (`CGO_ENABLED=0`) with optimized flags (`-s -w`, `-trimpath`) and optional plugins
- Syncthing is built from the official source release tarball with the pinned Go 1.26 toolchain
- Alpine provides the smallest possible runtime (~7 MB base) for static binaries
- Runtime dependencies are minimal: `su-exec`, `tini`, `tzdata`
- WireGuard UI additionally installs `wireguard-tools` and `iproute2` for interface management

Both base OS families share identical hardening and stripping scripts (`shared/hardening.sh`, `shared/strip.sh`) with automatic OS detection.

## Repository Structure

```
├── sonarr/          # Sonarr Dockerfile + entrypoint
├── radarr/          # Radarr Dockerfile + entrypoint
├── transmission/    # Transmission Dockerfile + entrypoint
├── prowlarr/        # Prowlarr Dockerfile + entrypoint
├── plex/            # Plex Dockerfile + entrypoint
├── dashy/           # Dashy Dockerfile + entrypoint (Alpine)
├── wireguard-ui/    # WireGuard UI Dockerfile + entrypoint (Alpine)
├── syncthing/       # Syncthing Dockerfile + entrypoint (Alpine)
├── caddy/           # Caddy reverse proxy Dockerfile + entrypoint (Alpine)
├── shared/          # Common hardening + stripping scripts
│   ├── hardening.sh # SUID/SGID removal, cleanup, crontab purge
│   └── strip.sh     # Package manager + tool removal (Debian + Alpine)
├── .github/         # CI/CD workflows, repository instructions, Scorecard
├── renovate.json5   # Renovate config for hardening-targeted update PRs
├── SECURITY.md      # Security policy, vulnerability reporting, verification
├── CONTRIBUTING.md  # Development and contribution guide
└── CODEOWNERS       # Code ownership and review requirements
```

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
