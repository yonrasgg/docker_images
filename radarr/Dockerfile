# =============================================================================
# Hardened Radarr Docker Image
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG BASE_IMAGE=debian:bookworm-slim@sha256:f06537653ac770703bc45b4b113475bd402f451e85223f0f2837acbf89ab020a
ARG GO_IMAGE=golang:1.26-alpine@sha256:f85330846cde1e57ca9ec309382da3b8e6ae3ab943d2739500e08c86393a21b1

# --- Stage 1: Build gosu from source with current Go toolchain ---
# The upstream gosu binary (v1.19) is compiled with Go 1.24.6, which embeds
# 30+ known Go stdlib CVEs. Building from source with the current pinned
# Go 1.26 toolchain reduces that exposure.
FROM ${GO_IMAGE} AS gosu-builder

ARG GOSU_VERSION=1.19

RUN apk add --no-cache git && \
    git clone --branch "${GOSU_VERSION}" --depth 1 \
      https://github.com/tianon/gosu.git /src/gosu

WORKDIR /src/gosu

RUN CGO_ENABLED=0 go build -ldflags='-s -w' -o /usr/local/bin/gosu .

# --- Stage 2: Download application ---
FROM ${BASE_IMAGE} AS downloader

ARG RADARR_BRANCH=master
# renovate: datasource=github-releases depName=Radarr/Radarr versioning=loose
ARG RADARR_VERSION=6.1.1.10360
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
      "https://github.com/Radarr/Radarr/releases/download/v${RADARR_VERSION}/Radarr.${RADARR_BRANCH}.${RADARR_VERSION}.linux-core-${ARCH}.tar.gz"; \
    mkdir -p /opt/radarr; \
    tar -xzf /tmp/radarr.tar.gz -C /opt/radarr --strip-components=1; \
    rm -f /tmp/radarr.tar.gz; \
    rm -rf /opt/radarr/Radarr.Update

# --- Stage 3: Runtime ---
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
      libicu72 \
      libsqlite3-0 \
      libssl3 \
      mediainfo \
      tini \
      tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# gosu built from source in gosu-builder stage with the current pinned
# Go 1.26 toolchain, avoiding the older upstream pre-compiled binary (Go 1.24.6).
COPY --from=gosu-builder /usr/local/bin/gosu /usr/sbin/gosu
RUN chmod +x /usr/sbin/gosu && gosu --version && gosu nobody true

COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media

COPY --from=downloader /opt/radarr /opt/radarr

RUN mkdir -p /config /downloads /movies && \
    chown -R media:media /opt/radarr /config /downloads /movies

COPY radarr/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

EXPOSE 7878

VOLUME ["/config", "/downloads", "/movies"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD bash -c 'exec 3<>/dev/tcp/localhost/7878 && printf "GET /ping HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n" >&3 && IFS= read -r status <&3 && printf "%s\n" "$status" | grep -Eq "^HTTP/[0-9.]+ 2[0-9][0-9]( |$)"' || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/opt/radarr/Radarr", "-nobrowser", "-data=/config"]
