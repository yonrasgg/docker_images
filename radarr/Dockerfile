# =============================================================================
# Hardened Radarr Docker Image
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG BASE_IMAGE=debian:bookworm-slim

# --- Stage 1: Download application ---
FROM ${BASE_IMAGE} AS downloader

ARG RADARR_BRANCH=master
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
    curl -fsSL -o /tmp/radarr.tar.gz \
      "https://radarr.servarr.com/v1/update/${RADARR_BRANCH}/updatefile?os=linux&runtime=netcore&arch=${ARCH}"; \
    mkdir -p /opt/radarr; \
    tar -xzf /tmp/radarr.tar.gz -C /opt/radarr --strip-components=1; \
    rm -f /tmp/radarr.tar.gz; \
    rm -rf /opt/radarr/Radarr.Update

# --- Stage 2: Runtime ---
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Radarr" \
      org.opencontainers.image.description="Security-hardened Radarr movie collection manager" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/radarr" \
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

COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media

COPY --from=downloader /opt/radarr /opt/radarr

RUN mkdir -p /config /downloads /movies && \
    chown -R media:media /opt/radarr /config /downloads /movies

COPY radarr/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 7878

VOLUME ["/config", "/downloads", "/movies"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:7878/ping || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/opt/radarr/Radarr", "-nobrowser", "-data=/config"]
