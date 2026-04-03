# =============================================================================
# Hardened WireGuard UI Docker Image (Alpine-based)
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
#
# NOTE: For live WireGuard interface management (wg-quick up/down), the
# container requires --cap-add NET_ADMIN --cap-add NET_RAW. Without these
# capabilities the UI operates in config-generation-only mode.
# =============================================================================

ARG GO_IMAGE=golang:1.26-alpine
ARG ALPINE_IMAGE=alpine:3.21

# --- Stage 1: Compile from source ---
FROM ${GO_IMAGE} AS builder

ARG WG_UI_VERSION=v0.6.2

WORKDIR /src

RUN apk add --no-cache git build-base

RUN git clone --branch "${WG_UI_VERSION}" --depth 1 \
      https://github.com/ngoduykhanh/wireguard-ui.git . && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /wireguard-ui

# --- Stage 2: Hardened Runtime ---
FROM ${ALPINE_IMAGE}

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened WireGuard UI" \
      org.opencontainers.image.description="Security-hardened WireGuard UI web interface (Alpine)" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/wireguard-ui" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
# wireguard-tools: provides wg and wg-quick for interface management
# iproute2: provides ip command required by wg-quick
RUN apk update && apk upgrade && \
    apk add --no-cache \
      curl \
      iproute2 \
      su-exec \
      tini \
      tzdata \
      wireguard-tools && \
    rm -rf /var/cache/apk/*

# Apply hardening
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN addgroup -g 1000 media && \
    adduser -u 1000 -G media -h /data -s /sbin/nologin -D media

# Copy compiled binary from builder
COPY --from=builder /wireguard-ui /usr/local/bin/wireguard-ui

# Create data and WireGuard config directories
RUN mkdir -p /data /etc/wireguard && \
    chown -R media:media /data /etc/wireguard

COPY wireguard-ui/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

ENV HOME=/data PUID=1000 PGID=1000 TZ=UTC

EXPOSE 5000

VOLUME ["/data", "/etc/wireguard"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -fsS http://localhost:5000/ || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/usr/local/bin/wireguard-ui"]
