# =============================================================================
# Hardened Prowlarr Docker Image
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG BASE_IMAGE=debian:bookworm-slim

# --- Stage 1: Download application ---
FROM ${BASE_IMAGE} AS downloader

ARG PROWLARR_BRANCH=master
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
    curl -fsSL -o /tmp/prowlarr.tar.gz \
      "https://prowlarr.servarr.com/v1/update/${PROWLARR_BRANCH}/updatefile?os=linux&runtime=netcore&arch=${ARCH}"; \
    mkdir -p /opt/prowlarr; \
    tar -xzf /tmp/prowlarr.tar.gz -C /opt/prowlarr --strip-components=1; \
    rm -f /tmp/prowlarr.tar.gz; \
    rm -rf /opt/prowlarr/Prowlarr.Update

# --- Stage 2: Runtime ---
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Prowlarr" \
      org.opencontainers.image.description="Security-hardened Prowlarr indexer manager for Usenet and BitTorrent" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/prowlarr" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      libicu72 \
      libsqlite3-0 \
      libssl3 \
      tini \
      tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

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

# Apply hardening (before user creation)
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media

# Copy application from downloader
COPY --from=downloader /opt/prowlarr /opt/prowlarr

# Create directory structure with correct ownership
RUN mkdir -p /config && \
    chown -R media:media /opt/prowlarr /config

COPY prowlarr/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

EXPOSE 9696

VOLUME ["/config"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:9696/ping || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/opt/prowlarr/Prowlarr", "-nobrowser", "-data=/config"]
