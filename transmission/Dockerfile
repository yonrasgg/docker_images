# =============================================================================
# Hardened Transmission Docker Image
# Multi-stage, non-root, minimal attack surface
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

# --- Stage 2: Compile Transmission from source ---
FROM ${BASE_IMAGE} AS builder

ARG TRANSMISSION_VERSION=4.1.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      gettext \
      libcurl4-openssl-dev \
      libdeflate-dev \
      libevent-dev \
      libminiupnpc-dev \
      libnatpmp-dev \
      libpsl-dev \
      libssl-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Download and extract source (vendored deps included in release tarball)
RUN curl -fsSL -o /tmp/transmission.tar.xz \
      "https://github.com/transmission/transmission/releases/download/${TRANSMISSION_VERSION}/transmission-${TRANSMISSION_VERSION}.tar.xz" && \
    tar -xJf /tmp/transmission.tar.xz -C /src --strip-components=1 && \
    rm -f /tmp/transmission.tar.xz

# Build daemon + CLI utilities only (no GTK/Qt/Mac GUI)
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DENABLE_DAEMON=ON \
      -DENABLE_GTK=OFF \
      -DENABLE_QT=OFF \
      -DENABLE_MAC=OFF \
      -DENABLE_CLI=OFF \
      -DENABLE_UTILS=ON \
      -DENABLE_TESTS=OFF \
      -DINSTALL_DOC=OFF \
      -DINSTALL_LIB=OFF && \
    cmake --build build -j"$(nproc)" && \
    cmake --install build

# --- Stage 3: Runtime ---
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Transmission" \
      org.opencontainers.image.description="Security-hardened Transmission BitTorrent client" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/transmission" \
      org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      libcurl4 \
      libdeflate0 \
      libevent-2.1-7 \
      libminiupnpc17 \
      libnatpmp1 \
      libpsl5 \
      libssl3 \
      tini \
      tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# gosu built from source in gosu-builder stage (Go 1.26.1) — eliminates
# 30+ Go stdlib CVEs embedded in the upstream pre-compiled binary (Go 1.24.6).
COPY --from=gosu-builder /usr/local/bin/gosu /usr/sbin/gosu
RUN chmod +x /usr/sbin/gosu && gosu --version && gosu nobody true

# Apply hardening (before user creation)
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media

# Copy compiled binaries from builder
COPY --from=builder /usr/local/bin/transmission-daemon /usr/local/bin/transmission-daemon
COPY --from=builder /usr/local/bin/transmission-remote /usr/local/bin/transmission-remote
COPY --from=builder /usr/local/bin/transmission-create /usr/local/bin/transmission-create
COPY --from=builder /usr/local/bin/transmission-edit /usr/local/bin/transmission-edit
COPY --from=builder /usr/local/bin/transmission-show /usr/local/bin/transmission-show
COPY --from=builder /usr/local/share/transmission/ /usr/local/share/transmission/

# Create directory structure with correct ownership
RUN mkdir -p /config /downloads /watch && \
    chown -R media:media /config /downloads /watch

COPY transmission/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

# Transmission ports: 9091 (web UI / RPC), 51413 (peer connections TCP+UDP)
EXPOSE 9091 51413/tcp 51413/udp

VOLUME ["/config", "/downloads", "/watch"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -fsS http://localhost:9091/transmission/web/ || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["transmission-daemon", "-f", "-g", "/config"]
