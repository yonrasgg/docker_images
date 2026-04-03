# =============================================================================
# Hardened Caddy Docker Image (Alpine-based)
# Multi-stage, non-root, minimal attack surface
# Custom build via xcaddy with optimized flags and optional plugins
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG GO_IMAGE=golang:1.24-alpine
ARG ALPINE_IMAGE=alpine:3.21

# --- Stage 1: Build Caddy from source with xcaddy ---
FROM ${GO_IMAGE} AS builder

ARG CADDY_VERSION=v2.9.1
# Add xcaddy plugins as build args for easy customization
ARG CADDY_PLUGINS=""

ENV CGO_ENABLED=0 \
    GOOS=linux

WORKDIR /build

RUN apk add --no-cache git

# Install xcaddy — the official Caddy build tool
# hadolint ignore=DL3059
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@v0.4.4

# Build a minimal, statically-linked Caddy binary.
# - nobadger,nomysql,nopgx: disable unused storage backends
# - netgo,osusergo: pure-Go networking and user lookup (no CGO)
# - -s -w: strip debug symbols and DWARF info
# - -trimpath: remove local filesystem paths from binary
# hadolint ignore=DL4006
RUN set -eu; \
    XCADDY_CMD="xcaddy build ${CADDY_VERSION}"; \
    if [ -n "${CADDY_PLUGINS}" ]; then \
      for plugin in ${CADDY_PLUGINS}; do \
        XCADDY_CMD="${XCADDY_CMD} --with ${plugin}"; \
      done; \
    fi; \
    eval "${XCADDY_CMD}" \
      --output /build/caddy && \
    chmod +x /build/caddy && \
    /build/caddy version

# --- Stage 2: Hardened Runtime ---
FROM ${ALPINE_IMAGE}

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Caddy" \
      org.opencontainers.image.description="Security-hardened Caddy web server and reverse proxy (Alpine)" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/caddy" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
# ca-certificates: required for ACME/TLS certificate validation
# libcap: provides setcap for NET_BIND_SERVICE on the caddy binary
RUN apk update && apk upgrade && \
    apk add --no-cache \
      ca-certificates \
      curl \
      libcap \
      su-exec \
      tini \
      tzdata && \
    rm -rf /var/cache/apk/*

# Apply hardening
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN addgroup -g 1000 media && \
    adduser -u 1000 -G media -h /data -s /sbin/nologin -D media

# Copy compiled binary from builder
COPY --from=builder /build/caddy /usr/bin/caddy

# Allow Caddy to bind to privileged ports (80, 443) without running as root
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy

# Create data and config directories
# /data: certificate storage, private keys — MUST be persistent (not a cache)
# /config: Caddy auto-save config (JSON admin API state)
# /etc/caddy: user-provided Caddyfile mount point
RUN mkdir -p /data /config /etc/caddy && \
    chown -R media:media /data /config /etc/caddy

COPY caddy/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

ENV HOME=/data \
    PUID=1000 \
    PGID=1000 \
    TZ=UTC \
    XDG_DATA_HOME=/data \
    XDG_CONFIG_HOME=/config

EXPOSE 80 443 443/udp 2019

VOLUME ["/data", "/config", "/etc/caddy"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -fsS http://localhost:2019/config/ || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/usr/bin/caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
