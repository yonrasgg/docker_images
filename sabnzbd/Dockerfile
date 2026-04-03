# =============================================================================
# Hardened SABnzbd Docker Image
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG PYTHON_IMAGE=python:3.13-slim-bookworm
ARG BASE_IMAGE=debian:bookworm-slim

# --- Stage 1: Download and prepare ---
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
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --prefix=/install \
      -r /opt/sabnzbd/requirements.txt && \
    pip install --no-cache-dir --prefix=/install --force-reinstall --no-deps \
      "requests>=2.33.0" \
      "cryptography>=46.0.5" \
      "urllib3>=2.6.3" \
      "ujson>=5.12.0" \
      "pyjwt>=2.12.0" \
      "orjson>=3.11.6"

# --- Stage 2: Runtime ---
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

# Download gosu from upstream — Debian packages gosu 1.14 compiled with Go 1.19,
# which embeds 30+ known Go stdlib CVEs. Using upstream binary (Go 1.24+) resolves all.
ARG GOSU_VERSION=1.19
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    curl -fsSL -o /usr/sbin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}"; \
    curl -fsSL -o /tmp/gosu.sha256 "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/SHA256SUMS"; \
    grep "gosu-${dpkgArch}$" /tmp/gosu.sha256 | sed "s|gosu-${dpkgArch}|/usr/sbin/gosu|" | sha256sum -c -; \
    rm -f /tmp/gosu.sha256; \
    chmod +x /usr/sbin/gosu; \
    gosu --version; \
    gosu nobody true

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
