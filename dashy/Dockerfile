# =============================================================================
# Hardened Dashy Docker Image (Alpine-based)
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG NODE_IMAGE=node:20-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293

# --- Stage 1: Download and build ---
FROM ${NODE_IMAGE} AS builder

# renovate: datasource=github-releases depName=Lissy93/dashy
ARG DASHY_VERSION=3.3.0

WORKDIR /app

RUN apk add --no-cache curl git

# Download the pinned Dashy release
# hadolint ignore=DL4006
RUN set -eux; \
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
      su-exec \
      tini \
      tzdata && \
    rm -rf /var/cache/apk/* && \
    # Remove Python (shipped by node:20-alpine for node-gyp builds) —
    # not needed at Dashy runtime and contains flagged cryptography CVE
    rm -rf /usr/lib/python* /usr/local/lib/python* \
           /usr/bin/python* /usr/local/bin/python* \
           /usr/lib/libpython* /usr/local/lib/libpython* \
           /usr/include/python* /usr/local/include/python* && \
    # Remove npm, npx, corepack, and yarn — only needed during build stage.
    # These ship with 15+ HIGH CVEs in bundled deps (tar, minimatch, cross-spawn,
    # glob, brace-expansion) that are NOT reachable at Dashy runtime.
    rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/lib/node_modules/corepack \
           /usr/local/lib/node_modules/yarn \
           /usr/local/bin/npm /usr/local/bin/npx \
           /usr/local/bin/corepack \
           /usr/local/bin/yarn /usr/local/bin/yarnpkg

# Apply hardening
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user (remove node user/group from base image first)
RUN deluser --remove-home node 2>/dev/null || true && \
    delgroup node 2>/dev/null || true && \
    addgroup -g 1000 media && \
    adduser -u 1000 -G media -h /app -s /sbin/nologin -D media

# Copy built application from builder
COPY --from=builder /app /app

# Dashy defaults to port 4000; override to match EXPOSE
ENV PORT=8080

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
  CMD wget -qO /dev/null http://localhost:8080/ || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["node", "server.js"]
