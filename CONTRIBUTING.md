# Contributing

Thank you for your interest in contributing to this project.

## Development Setup

1. Fork and clone the repository
2. Install Docker with BuildKit enabled
3. Install development tools:
   ```bash
   # Dockerfile linting
   brew install hadolint   # or: docker run --rm -i hadolint/hadolint < Dockerfile

   # Shell script linting
   brew install shellcheck

   # Vulnerability scanning
   brew install trivy

   # Image signature verification
   brew install cosign
   ```

## Building an Image Locally

All Dockerfiles reference `shared/hardening.sh` via `COPY`, so builds must run from the repo root:

```bash
# Build a specific image (Debian-based)
docker build -f sonarr/Dockerfile -t sonarr:dev .

# Build a specific image (Alpine Node.js)
docker build -f dashy/Dockerfile -t dashy:dev .

# Build a specific image (Alpine Go)
docker build -f wireguard-ui/Dockerfile -t wireguard-ui:dev .
docker build -f syncthing/Dockerfile -t syncthing:dev .
docker build -f caddy/Dockerfile -t caddy:dev .
```

## Testing an Image

```bash
# Run with test configuration
docker run --rm -it \
  -e PUID=$(id -u) -e PGID=$(id -g) \
  -v /tmp/test-config:/config \
  sonarr:dev

# Scan for vulnerabilities (must pass 0 CRITICAL/HIGH)
trivy image --severity CRITICAL,HIGH sonarr:dev

# Lint the Dockerfile
hadolint sonarr/Dockerfile

# Lint shell scripts
shellcheck sonarr/entrypoint.sh shared/hardening.sh shared/strip.sh
```

## Adding a New Image

1. Create a directory: `<image-name>/`
2. Add `Dockerfile` following the existing patterns:
   - Multi-stage build (builder + runtime)
   - **Debian `bookworm-slim`**: for .NET/media apps (sonarr, radarr, prowlarr, plex) or C++ apps (transmission)
   - **Alpine `node:20-alpine`**: for pure Node.js apps (dashy)
   - **Alpine `alpine:3.21`**: for statically-compiled Go binaries (wireguard-ui, syncthing, caddy)
   - See [Architecture Decisions](README.md#architecture-decisions) for rationale
   - Apply `shared/hardening.sh` for security hardening
   - Apply `shared/strip.sh` as the final build step (after user creation)
   - Non-root user via `gosu` (Debian) or `su-exec` (Alpine)
   - `tini` as PID 1
   - `HEALTHCHECK` directive
   - OCI labels (`org.opencontainers.image.*`)
3. Add `entrypoint.sh` with PUID/PGID support
4. Add to `.dockerignore` whitelist
5. Add the image to ALL CI workflow matrices:
   - `.github/workflows/ci-gate.yml` (hadolint, build-and-scan, smoke-test)
   - `.github/workflows/build-push.yml` (build matrix with platforms)
   - `.github/workflows/security-scan.yml` (grype-scan matrix)
6. Add Dependabot config in `.github/dependabot.yml`
7. Update documentation:
   - `README.md` — image table, architecture section, repo structure tree
   - `SECURITY.md` — supported versions table
   - `CONTRIBUTING.md` — build examples if applicable

## Branching Workflow

All work happens on the `hardening` branch. The `main` branch only receives tested, scanned, compliant code via PR.

```bash
# 1. Start from the hardening branch
git checkout hardening
git pull origin hardening

# 2. Make your changes
#    Edit Dockerfiles, entrypoints, shared scripts, etc.

# 3. Commit and push
git add -A
git commit -m "fix: resolve Trivy CVE in sonarr base image"
git push origin hardening
#    → CI Gate runs automatically (lint → build → scan → smoke test)

# 4. Wait for CI Gate to pass
#    Check: https://github.com/yonrasgg/docker_images/actions/workflows/ci-gate.yml

# 5. Open a PR: hardening → main
#    → CI Gate runs again on the PR
#    → CODEOWNER review required
#    → Squash merge when approved

# 6. After merge to main:
#    → Publish workflow runs automatically
#    → Images are built, scanned again, pushed, signed, and attested
```

**Never push directly to `main`.** Branch protection enforces this.

## Supply Chain Security Requirements

All CI/CD changes must follow these rules:

- **Pin GitHub Actions by commit SHA** — never use floating tags (`@v3`, `@main`, `@latest`)
  ```yaml
  # Correct
  uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

  # Incorrect
  uses: actions/checkout@v4
  ```
- **Do not disable Trivy gate** — the build must fail on CRITICAL/HIGH CVEs
- **Do not skip Cosign signing** — every pushed image must be signed
- **Do not remove SBOM generation** — every image must have an SPDX SBOM attestation
- **Add SHA comments** — include the version tag as a comment after the SHA for readability

## Code Standards

- **Dockerfiles**: Pass `hadolint` with no warnings
- **Shell scripts**: Pass `shellcheck` with no warnings
- **Commits**: Use conventional commit messages (`feat:`, `fix:`, `security:`, `ci:`)
- **Actions**: All third-party actions pinned by full commit SHA

## Pull Request Process

1. Work on the `hardening` branch — push commits there
2. CI Gate must pass (`✅ All CI Gates Passed` is green)
3. Open a PR from `hardening` to `main`
4. Trivy scan must report 0 CRITICAL/HIGH vulnerabilities
5. Smoke tests must pass (container starts, healthcheck responds)
6. Update relevant documentation (README, SECURITY, CONTRIBUTING)
7. One approval required from a CODEOWNER
8. Squash merge — keep `main` history clean
