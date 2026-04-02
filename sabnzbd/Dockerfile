# =============================================================================
# Hardened SABnzbd Docker Image
# Multi-stage, non-root, minimal attack surface
# https://github.com/yonrasgg/docker_images
# =============================================================================

ARG PYTHON_IMAGE=python:3.13-slim-bookworm
ARG BASE_IMAGE=debian:bookworm-slim

# --- Stage 1: Download and prepare ---
FROM ${PYTHON_IMAGE} AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download latest SABnzbd release
RUN set -eux; \
    SABNZBD_VERSION=$(curl -sL https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest | \
      grep '"tag_name"' | sed 's/.*"tag_name": *"//;s/".*//'); \
    echo "Downloading SABnzbd ${SABNZBD_VERSION}"; \
    curl -fsSL -o /tmp/sabnzbd.tar.gz \
      "https://github.com/sabnzbd/sabnzbd/releases/download/${SABNZBD_VERSION}/SABnzbd-${SABNZBD_VERSION}-src.tar.gz"; \
    mkdir -p /opt/sabnzbd; \
    tar -xzf /tmp/sabnzbd.tar.gz -C /opt/sabnzbd --strip-components=1; \
    rm -f /tmp/sabnzbd.tar.gz

# Install Python dependencies (upgrade pip first for security patches)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --prefix=/install \
      -r /opt/sabnzbd/requirements.txt

# --- Stage 2: Runtime ---
FROM ${PYTHON_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="yonrasgg" \
      org.opencontainers.image.title="Hardened SABnzbd" \
      org.opencontainers.image.description="Security-hardened SABnzbd Usenet downloader" \
      org.opencontainers.image.url="https://github.com/yonrasgg/docker_images" \
      org.opencontainers.image.source="https://github.com/yonrasgg/docker_images/tree/main/sabnzbd" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="yonrasgg"

# Install runtime dependencies and apply all available security patches
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gosu \
      par2 \
      p7zip-full \
      tini \
      tzdata \
      unrar-free && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Apply hardening
COPY shared/hardening.sh /tmp/hardening.sh
RUN chmod +x /tmp/hardening.sh && /tmp/hardening.sh && rm /tmp/hardening.sh

# Create non-root user
RUN groupadd -g 1000 media && \
    useradd -u 1000 -g media -d /config -s /usr/sbin/nologin media

# Copy Python packages and application
COPY --from=builder /install /usr/local
COPY --from=builder /opt/sabnzbd /opt/sabnzbd

RUN mkdir -p /config /downloads /incomplete-downloads && \
    chown -R media:media /opt/sabnzbd /config /downloads /incomplete-downloads

COPY sabnzbd/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Remove package manager and unnecessary components to prevent runtime tampering
# Runs last to preserve build-time tools (groupadd, useradd, find, etc.)
RUN rm -rf /usr/bin/apt* /usr/bin/dpkg* /usr/lib/apt /usr/lib/dpkg \
           /etc/apt /var/lib/apt /var/lib/dpkg \
           /usr/bin/find /usr/bin/locate /usr/bin/xargs \
           /usr/bin/passwd /usr/sbin/adduser /usr/sbin/deluser \
           /usr/sbin/groupadd /usr/sbin/useradd /usr/sbin/newusers \
           /usr/bin/wall /usr/bin/write \
           /usr/share/perl* /usr/share/zsh 2>/dev/null || true

EXPOSE 8080

VOLUME ["/config", "/downloads", "/incomplete-downloads"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:8080/api?mode=version || exit 1

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["python3", "/opt/sabnzbd/SABnzbd.py", "--server", "0.0.0.0:8080", "--config-file", "/config", "--browser", "0"]
