# =============================================================================
# Hardened SABnzbd Docker Image
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG PYTHON_IMAGE=python:3.13-slim-bookworm
ARG BASE_IMAGE=debian:bookworm-slim
ARG GO_IMAGE=golang:1.26-alpine@sha256:2389ebfa5b7f43eeafbd6be0c3700cc46690ef842ad962f6c5bd6be49ed82039

# --- Stage 1: Build gosu from source with current Go toolchain ---
# The upstream gosu binary (v1.19) is compiled with Go 1.24.6, which embeds
# 30+ known Go stdlib CVEs. Building from source with Go 1.26.1 eliminates them.
FROM ${GO_IMAGE} AS gosu-builder

ARG GOSU_VERSION=1.19

RUN apk add --no-cache git && \
    git clone --branch "${GOSU_VERSION}" --depth 1 \
      https://github.com/tianon/gosu.git /src/gosu

WORKDIR /src/gosu

RUN CGO_ENABLED=0 go build -ldflags='-s -w' -o /usr/local/bin/gosu .

# --- Stage 2: Download and prepare ---
FROM ${PYTHON_IMAGE} AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download latest SABnzbd release
RUN set -eux; \
    SABNZBD_VERSION=$(curl -sL https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest | \
      grep '"tag_name"' | sed 's/.*"tag_name": *"//;s/".*//'); \
    echo "Downloading SABnzbd ${SABNZBD_VERSION}"; \
    curl -fsSL -o /tmp/sabnzbd.tar.gz \
      "https://github.com/sabnzbd/sabnzbd/releases/download/${SABNZBD_VERSION}/SABnzbd-${SABNZBD_VERSION}-src.tar.gz"; \
    mkdir -p /opt/sabnzbd; \
    tar -xzf /tmp/sabnzbd.tar.gz -C /opt/sabnzbd --strip-components=1; \
    rm -f /tmp/sabnzbd.tar.gz; \
    # Remove Node.js frontend tooling files (not needed at Python runtime,
    # and they contain transitive CVEs that Trivy flags as false positives)
    rm -rf /opt/sabnzbd/package.json /opt/sabnzbd/package-lock.json \
           /opt/sabnzbd/node_modules /opt/sabnzbd/yarn.lock \
           /opt/sabnzbd/.npm /opt/sabnzbd/Gruntfile.js /opt/sabnzbd/gulpfile.js

# Install Python dependencies (upgrade pip first for security patches)
# SABnzbd's requirements.txt pins exact versions that may have known CVEs.
# We loosen those pins to allow patched releases before installing.
RUN pip install --no-cache-dir --upgrade pip && \
    sed -i \
      -e 's/^cryptography[=<>~!].*/cryptography>=46.0.5/' \
      -e 's/^orjson[=<>~!].*/orjson>=3.11.6/' \
      -e 's/^PyJWT[=<>~!].*/PyJWT>=2.12.0/' \
      -e 's/^pyjwt[=<>~!].*/pyjwt>=2.12.0/' \
      -e 's/^requests[=<>~!].*/requests>=2.33.0/' \
      -e 's/^ujson[=<>~!].*/ujson>=5.12.0/' \
      -e 's/^urllib3[=<>~!].*/urllib3>=2.6.3/' \
      /opt/sabnzbd/requirements.txt && \
    pip install --no-cache-dir --prefix=/install \
      -r /opt/sabnzbd/requirements.txt

# --- Stage 3: Runtime ---
FROM ${PYTHON_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened SABnzbd" \
      org.opencontainers.image.description="Security-hardened SABnzbd Usenet downloader" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/sabnzbd" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
# Replace p7zip-full with 7zip — p7zip is unmaintained upstream with 5+ HIGH CVEs
# (CVE-2023-31102, CVE-2023-40481, CVE-2023-52168, CVE-2025-11001, CVE-2025-11002).
# 7zip (22.01+dfsg-8+deb12u1) is actively maintained and security-patched in bookworm.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      7zip \
      ca-certificates \
      curl \
      par2 \
      tini \
      tzdata \
      unrar-free && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/* && \
    # SABnzbd expects '7za' or '7z' binary; Debian 7zip package provides '7zz'.
    # Create backwards-compatible symlinks for SABnzbd auto-detection.
    ln -sf /usr/bin/7zz /usr/bin/7z && \
    ln -sf /usr/bin/7zz /usr/bin/7za

# gosu built from source in gosu-builder stage (Go 1.26.1) — eliminates
# 30+ Go stdlib CVEs embedded in the upstream pre-compiled binary (Go 1.24.6).
COPY --from=gosu-builder /usr/local/bin/gosu /usr/sbin/gosu
RUN chmod +x /usr/sbin/gosu && gosu --version && gosu nobody true

# Apply hardening
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media

# Copy Python packages and application
COPY --from=builder /install /usr/local
COPY --from=builder /opt/sabnzbd /opt/sabnzbd

# Remove any Node.js frontend tooling that survived the build (defense-in-depth)
RUN find /opt/sabnzbd /usr/local \( -name "package.json" -o -name "package-lock.json" \
      -o -name "yarn.lock" -o -name "node_modules" \) -exec rm -rf {} + 2>/dev/null || true

RUN mkdir -p /config /downloads /incomplete-downloads && \
    chown -R media:media /opt/sabnzbd /config /downloads /incomplete-downloads

COPY sabnzbd/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

EXPOSE 8080

VOLUME ["/config", "/downloads", "/incomplete-downloads"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:8080/api?mode=version || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["python3", "/opt/sabnzbd/SABnzbd.py", "--server", "0.0.0.0:8080", "--config-file", "/config", "--browser", "0"]
