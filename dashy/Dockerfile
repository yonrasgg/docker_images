# =============================================================================
# Hardened Dashy Docker Image (Alpine-based)
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG NODE_IMAGE=node:20-alpine

# --- Stage 1: Download and build ---
FROM ${NODE_IMAGE} AS builder

WORKDIR /app

RUN apk add --no-cache curl git

# Download latest Dashy release
RUN set -eux; \
    DASHY_VERSION=$(curl -sL https://api.github.com/repos/Lissy93/dashy/releases/latest | \
      grep '"tag_name"' | sed 's/.*"tag_name": *"//;s/".*//'); \
    echo "Downloading Dashy ${DASHY_VERSION}"; \
    curl -fsSL -o /tmp/dashy.tar.gz \
      "https://github.com/Lissy93/dashy/archive/refs/tags/${DASHY_VERSION}.tar.gz"; \
    tar -xzf /tmp/dashy.tar.gz -C /app --strip-components=1; \
    rm -f /tmp/dashy.tar.gz

# Install dependencies and build production assets
RUN yarn install --frozen-lockfile --network-timeout 300000 && \
    yarn build && \
    rm -rf node_modules && \
    yarn install --frozen-lockfile --production --network-timeout 300000

# --- Stage 2: Runtime ---
FROM ${NODE_IMAGE}

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened Dashy" \
      org.opencontainers.image.description="Security-hardened Dashy self-hosted dashboard (Alpine)" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/dashy" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
RUN apk update && apk upgrade && \
    apk add --no-cache \
      curl \
      su-exec \
      tini \
      tzdata && \
    rm -rf /var/cache/apk/*

# Apply hardening
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN addgroup -g 1000 media && \
    adduser -u 1000 -G media -h /app -s /sbin/nologin -D media

# Copy built application from builder
COPY --from=builder /app /app

RUN mkdir -p /app/user-data && \
    chown -R media:media /app

COPY dashy/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Strip package manager and unnecessary tools (must run after user creation)
COPY shared/strip.sh /tmp/strip.sh
RUN chmod +x /tmp/strip.sh && /tmp/strip.sh && rm /tmp/strip.sh

EXPOSE 8080

VOLUME ["/app/user-data"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:8080/ || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["node", "server.js"]
