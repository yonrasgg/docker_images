# =============================================================================
# Hardened Syncthing Docker Image (Alpine-based)
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG ALPINE_IMAGE=alpine:3.21@sha256:c3f8e73fdb79deaebaa2037150150191b9dcbfba68b4a46d70103204c53f4709

# --- Stage 1: Download pre-built binary ---
FROM ${ALPINE_IMAGE} AS downloader

ARG TARGETARCH
ARG SYNCTHING_VERSION=v2.0.15

RUN apk add --no-cache curl ca-certificates

# Download pre-built binary and verify SHA256 checksum
# Syncthing publishes a PGP-signed sha256sum.txt.asc; we strip the
# PGP envelope and verify the hash for our architecture's tarball.
# hadolint ignore=DL4006
RUN set -eux; \
    curl -fsSL -o /tmp/syncthing.tar.gz \
      "https://github.com/syncthing/syncthing/releases/download/${SYNCTHING_VERSION}/syncthing-linux-${TARGETARCH}-${SYNCTHING_VERSION}.tar.gz"; \
    curl -fsSL -o /tmp/sha256sum.txt.asc \
      "https://github.com/syncthing/syncthing/releases/download/${SYNCTHING_VERSION}/sha256sum.txt.asc"; \
    sed -n '/^[a-f0-9]\{64\} /p' /tmp/sha256sum.txt.asc \
      | grep "syncthing-linux-${TARGETARCH}-${SYNCTHING_VERSION}.tar.gz" \
      | sed "s|syncthing-linux-${TARGETARCH}-${SYNCTHING_VERSION}.tar.gz|/tmp/syncthing.tar.gz|" \
      | sha256sum -c -; \
    mkdir -p /opt/syncthing; \
    tar -xzf /tmp/syncthing.tar.gz -C /opt/syncthing --strip-components=1; \
    rm -f /tmp/syncthing.tar.gz /tmp/sha256sum.txt.asc

# --- Stage 2: Hardened Runtime ---
FROM ${ALPINE_IMAGE}

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Syncthing" \
      org.opencontainers.image.description="Security-hardened Syncthing continuous file synchronization (Alpine)" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/syncthing" \
      org.opencontainers.image.licenses="MPL-2.0" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
RUN apk update && apk upgrade && \
    apk add --no-cache \
      curl \
      su-exec \
      tini \
      tzdata && \
    rm -rf /var/cache/apk/*

# Apply hardening
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN addgroup -g 1000 media && \
    adduser -u 1000 -G media -h /config -s /sbin/nologin -D media

# Copy Syncthing binary from downloader
COPY --from=downloader /opt/syncthing/syncthing /usr/local/bin/syncthing

# Create data directories
RUN mkdir -p /config /data && \
    chown -R media:media /config /data

COPY syncthing/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

ENV HOME=/config PUID=1000 PGID=1000 TZ=UTC \
    STGUIADDRESS=0.0.0.0:8384

EXPOSE 8384 22000/tcp 22000/udp 21027/udp

VOLUME ["/config", "/data"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -fsS http://localhost:8384/rest/noauth/health || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/usr/local/bin/syncthing", "--no-browser", "--home=/config"]
