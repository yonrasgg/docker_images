# =============================================================================
# Hardened Portainer Docker Image (Alpine-based)
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG ALPINE_IMAGE=alpine:3.21@sha256:c3f8e73fdb79deaebaa2037150150191b9dcbfba68b4a46d70103204c53f4709

# --- Stage 1: Download and verify official release artifact ---
FROM ${ALPINE_IMAGE} AS builder

ARG TARGETARCH
# renovate: datasource=github-releases depName=portainer/portainer
ARG PORTAINER_VERSION=2.41.0

RUN apk add --no-cache ca-certificates curl tar

# Download the official Portainer release tarball and validate it against
# Portainer's published SHA256 checksum before copying into runtime.
# hadolint ignore=DL4006
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) PORTAINER_ARCH="amd64" ;; \
      arm64) PORTAINER_ARCH="arm64" ;; \
      arm) PORTAINER_ARCH="arm" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    ASSET="portainer-${PORTAINER_VERSION}-linux-${PORTAINER_ARCH}"; \
    curl -fsSL -o "/tmp/${ASSET}.tar.gz" \
      "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/${ASSET}.tar.gz"; \
    curl -fsSL -o "/tmp/${ASSET}-checksum.txt" \
      "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/${ASSET}-checksum.txt"; \
    checksum_line="$(awk -v f="${ASSET}.tar.gz" '$2=="(" f ")" && $3=="=" {print $4 "  /tmp/" f}' "/tmp/${ASSET}-checksum.txt")"; \
    [ -n "${checksum_line}" ] || { \
      echo "Failed to find checksum for ${ASSET}.tar.gz in /tmp/${ASSET}-checksum.txt" >&2; \
      exit 1; \
    }; \
    printf '%s\n' "${checksum_line}" | sha256sum -c -; \
    mkdir -p /build/portainer; \
    tar -xzf "/tmp/${ASSET}.tar.gz" -C /build/portainer --strip-components=1; \
    rm -f "/tmp/${ASSET}.tar.gz" "/tmp/${ASSET}-checksum.txt"

# --- Stage 2: Hardened Runtime ---
FROM ${ALPINE_IMAGE}

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Portainer" \
      org.opencontainers.image.description="Security-hardened Portainer container management UI (Alpine)" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/portainer" \
      org.opencontainers.image.licenses="Zlib" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
RUN apk update && apk upgrade && \
    apk add --no-cache \
      ca-certificates \
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

# Copy Portainer binary and frontend assets from builder
COPY --from=builder /build/portainer /opt/portainer

# Create persistent data directory
RUN mkdir -p /data && \
    chown -R media:media /data /opt/portainer

COPY portainer/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

ENV HOME=/data \
    PUID=1000 \
    PGID=1000 \
    TZ=UTC

EXPOSE 8000 9000 9443

VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget -qO /dev/null http://localhost:9000/api/status || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/opt/portainer/portainer", "--http-enabled", "--bind", ":9000", "--data", "/data", "--assets", "/opt/portainer"]
