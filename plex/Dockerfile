# =============================================================================
# Hardened Plex Media Server Docker Image
# Multi-stage, non-root, minimal attack surface, HW transcoding ready
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG BASE_IMAGE=debian:bookworm-slim@sha256:f06537653ac770703bc45b4b113475bd402f451e85223f0f2837acbf89ab020a
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

# --- Stage 2: Download Plex ---
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

# --- Stage 3: Runtime ---
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Plex Media Server" \
      org.opencontainers.image.description="Security-hardened Plex Media Server with HW transcoding support" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/plex" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies (including Intel QSV/VA-API for HW transcoding on amd64)
# Apply all available security patches from Debian repos
ARG TARGETARCH
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      libdrm2 \
      libva-drm2 \
      libva2 \
      tini \
      tzdata \
      xmlstarlet && \
    if [ "$TARGETARCH" = "amd64" ]; then \
      apt-get install -y --no-install-recommends \
        intel-media-va-driver \
        mesa-va-drivers; \
    fi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# gosu built from source in gosu-builder stage (Go 1.26.1) — eliminates
# 30+ Go stdlib CVEs embedded in the upstream pre-compiled binary (Go 1.24.6).
COPY --from=gosu-builder /usr/local/bin/gosu /usr/sbin/gosu
RUN chmod +x /usr/sbin/gosu && gosu --version && gosu nobody true

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

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

# Plex ports: 32400 (web), 1900 (DLNA/UDP), 32469 (DLNA/TCP), 5353 (Bonjour)
EXPOSE 32400/tcp 1900/udp 32469/tcp 5353/udp

VOLUME ["/config", "/transcode", "/media"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -fsS http://localhost:32400/identity || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/opt/plex/Plex Media Server"]
