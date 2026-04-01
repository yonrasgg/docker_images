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
# Build a specific image
docker build -f sonarr/Dockerfile -t sonarr:dev .

# Build for a specific architecture
docker buildx build -f sonarr/Dockerfile --platform linux/arm64 -t sonarr:dev-arm64 .
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
shellcheck sonarr/entrypoint.sh shared/hardening.sh
```

## Adding a New Image

1. Create a directory: `<image-name>/`
2. Add `Dockerfile` following the existing patterns:
   - Multi-stage build (downloader + runtime)
   - Use `debian:bookworm-slim` as base (see [Architecture Decision](README.md#architecture-decision-debian-over-alpine) for rationale)
   - Apply `shared/hardening.sh`
   - Non-root user via `gosu`
   - `tini` as PID 1
   - `HEALTHCHECK` directive
   - OCI labels (`org.opencontainers.image.*`)
3. Add `entrypoint.sh` with PUID/PGID support
4. Add the image to `.github/workflows/build-push.yml` matrix
5. Add Dependabot config in `.github/dependabot.yml`
6. Update the image table in `README.md` and `SECURITY.md`

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

1. Ensure all CI checks pass (lint, scan, build)
2. Trivy scan must report 0 CRITICAL/HIGH vulnerabilities
3. Update relevant documentation (README, SECURITY, CONTRIBUTING)
4. One approval required from a CODEOWNER for merge
5. Squash merge preferred for clean history
