# =============================================================================
# Hardened Sonarr Docker Image
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG BASE_IMAGE=debian:bookworm-slim

# --- Stage 1: Download application ---
FROM ${BASE_IMAGE} AS downloader

ARG SONARR_BRANCH=main
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) ARCH="x64" ;; \
      arm64) ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/sonarr.tar.gz \
      "https://services.sonarr.tv/v1/download/${SONARR_BRANCH}/latest?version=4&os=linux&arch=${ARCH}"; \
    mkdir -p /opt/sonarr; \
    tar -xzf /tmp/sonarr.tar.gz -C /opt/sonarr --strip-components=1; \
    rm -f /tmp/sonarr.tar.gz; \
    rm -rf /opt/sonarr/Sonarr.Update

# --- Stage 2: Runtime ---
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Sonarr" \
      org.opencontainers.image.description="Security-hardened Sonarr PVR for Usenet and BitTorrent" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/sonarr" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gosu \
      libicu72 \
      libsqlite3-0 \
      libssl3 \
      mediainfo \
      tini \
      tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Apply hardening
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media

# Copy application from downloader
COPY --from=downloader /opt/sonarr /opt/sonarr

# Create directory structure with correct ownership
RUN mkdir -p /config /downloads /tv && \
    chown -R media:media /opt/sonarr /config /downloads /tv

COPY sonarr/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 8989

VOLUME ["/config", "/downloads", "/tv"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:8989/ping || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/opt/sonarr/Sonarr", "-nobrowser", "-data=/config"]
