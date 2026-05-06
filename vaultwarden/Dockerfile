# =============================================================================
# Hardened Vaultwarden Docker Image (Alpine-based)
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG RUST_MUSL_IMAGE=ghcr.io/blackdex/rust-musl:x86_64-musl-stable-1.95.0@sha256:14d946ad146135ba544832dd1989766fded7a0fbdfc3de7ebb7ecbb2d3683713
ARG WEB_VAULT_IMAGE=vaultwarden/web-vault@sha256:ca2a4251c4e63c9ad428262b4dd452789a1b9f6fce71da351e93dceed0d2edbe
ARG ALPINE_IMAGE=alpine:3.21@sha256:c3f8e73fdb79deaebaa2037150150191b9dcbfba68b4a46d70103204c53f4709

# --- Stage 1: Web Vault static assets ---
FROM ${WEB_VAULT_IMAGE} AS web-vault

# --- Stage 2: Build Vaultwarden from source ---
FROM ${RUST_MUSL_IMAGE} AS builder

# renovate: datasource=github-releases depName=dani-garcia/vaultwarden
ARG VAULTWARDEN_VERSION=1.36.0
ARG VAULTWARDEN_FEATURES=sqlite,mysql,postgresql,enable_mimalloc

WORKDIR /src

# Build a static MUSL binary from the upstream tagged release.
RUN set -eux; \
    git clone --branch "${VAULTWARDEN_VERSION}" --depth 1 https://github.com/dani-garcia/vaultwarden.git .; \
    CARGO_TARGET="${RUST_MUSL_CROSS_TARGET}"; \
    cargo build --release --target="${CARGO_TARGET}" --features "${VAULTWARDEN_FEATURES}"; \
    install -Dm755 "target/${CARGO_TARGET}/release/vaultwarden" /out/vaultwarden

# --- Stage 3: Hardened Runtime ---
FROM ${ALPINE_IMAGE}

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Vaultwarden" \
      org.opencontainers.image.description="Security-hardened Vaultwarden password manager server (Alpine)" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/vaultwarden" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
RUN apk update && apk upgrade && \
    apk add --no-cache \
      ca-certificates \
      libcrypto3 \
      libssl3 \
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

# Copy Vaultwarden binary and static web assets
COPY --from=builder /out/vaultwarden /usr/local/bin/vaultwarden
COPY --from=web-vault /web-vault /web-vault

# Create data directory
RUN mkdir -p /data && \
    chown -R media:media /data /web-vault

COPY vaultwarden/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

ENV HOME=/data \
    DATA_FOLDER=/data \
    PUID=1000 \
    PGID=1000 \
    ROCKET_ADDRESS=0.0.0.0 \
    ROCKET_PORT=80 \
    WEB_VAULT_FOLDER=/web-vault \
    TZ=UTC

EXPOSE 80

VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget -qO /dev/null http://localhost:80/alive || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/usr/local/bin/vaultwarden"]
