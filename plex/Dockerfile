# =============================================================================
# Hardened Plex Media Server Docker Image
# Multi-stage, non-root, minimal attack surface, HW transcoding ready
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG BASE_IMAGE=debian:bookworm-slim

# --- Stage 1: Download Plex ---
FROM ${BASE_IMAGE} AS downloader

ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download latest Plex Media Server
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) PLEX_ARCH="amd64" ;; \
      arm64) PLEX_ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    # Get download URL from Plex API
    PLEX_TOKEN="${PLEX_TOKEN:-}"; \
    DL_URL=$(curl -fsSL \
      "https://plex.tv/api/downloads/5.json" | \
      grep -oP '"url"\s*:\s*"https://downloads\.plex\.tv/plex-media-server-new/[^"]*'"${PLEX_ARCH}"'\.deb"' | \
      head -1 | \
      grep -oP 'https://[^"]+'); \
    curl -fsSL -o /tmp/plex.deb "${DL_URL}"; \
    mkdir -p /opt/plex; \
    dpkg-deb -x /tmp/plex.deb /opt/plex; \
    rm -f /tmp/plex.deb

# --- Stage 2: Runtime ---
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Plex Media Server" \
      org.opencontainers.image.description="Security-hardened Plex Media Server with HW transcoding support" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/plex" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies (including Intel QSV/VA-API for HW transcoding)
# Apply all available security patches from Debian repos
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gosu \
      intel-media-va-driver \
      libdrm2 \
      libva-drm2 \
      libva2 \
      mesa-va-drivers \
      tini \
      tzdata \
      xmlstarlet && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create plex user with video group access (for HW transcoding)
RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media && \
    usermod -aG video,render media 2>/dev/null || true

# Copy Plex from downloader
COPY --from=downloader /opt/plex/usr/lib/plexmediaserver /opt/plex

# Create directory structure
RUN mkdir -p /config /transcode /media && \
    chown -R media:media /opt/plex /config /transcode /media

COPY plex/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Plex ports: 32400 (web), 1900 (DLNA/UDP), 32469 (DLNA/TCP), 5353 (Bonjour)
EXPOSE 32400/tcp 1900/udp 32469/tcp 5353/udp

VOLUME ["/config", "/transcode", "/media"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -fsS http://localhost:32400/identity || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/opt/plex/Plex Media Server"]
