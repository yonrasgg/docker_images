# =============================================================================
# Hardened Jackett Docker Image
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG BASE_IMAGE=debian:bookworm-slim

# --- Stage 1: Download application ---
FROM ${BASE_IMAGE} AS downloader

ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) JACKETT_ARCH="AMDx64" ;; \
      arm64) JACKETT_ARCH="ARM64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/jackett.tar.gz \
      "https://github.com/Jackett/Jackett/releases/latest/download/Jackett.Binaries.Linux${JACKETT_ARCH}.tar.gz"; \
    mkdir -p /opt/jackett; \
    tar -xzf /tmp/jackett.tar.gz -C /opt/jackett --strip-components=1; \
    rm -f /tmp/jackett.tar.gz; \
    rm -rf /opt/jackett/Jackett.Update

# --- Stage 2: Runtime ---
FROM ${BASE_IMAGE}

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Jackett" \
      org.opencontainers.image.description="Security-hardened Jackett indexer proxy" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/jackett" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gosu \
      libicu72 \
      libssl3 \
      tini \
      tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media

COPY --from=downloader /opt/jackett /opt/jackett

RUN mkdir -p /config /downloads && \
    chown -R media:media /opt/jackett /config /downloads

COPY jackett/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 9117

VOLUME ["/config", "/downloads"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:9117/UI/Login || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/opt/jackett/jackett", "--NoUpdates", "--DataFolder=/config"]
