#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

for cmd in curl jq perl grep sed; do
  require_cmd "$cmd"
done

github_api() {
  local url="$1"

  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsSL \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "$url"
  else
    curl -fsSL \
      -H "Accept: application/vnd.github+json" \
      "$url"
  fi
}

github_latest_tag() {
  local repo="$1"

  github_api "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name'
}

strip_v() {
  printf '%s' "${1#v}"
}

plex_latest_version() {
  curl -fsSL 'https://plex.tv/api/downloads/5.json' | jq -r '.computer.Linux.version'
}

update_arg() {
  local file="$1"
  local arg_name="$2"
  local value="$3"
  local current

  current="$(grep -E "^ARG ${arg_name}=" "$file" | sed "s/^ARG ${arg_name}=//")"

  if [ -z "$current" ]; then
    echo "Failed to find ARG ${arg_name} in ${file}" >&2
    exit 1
  fi

  if [ "$current" = "$value" ]; then
    return 0
  fi

  echo "Updating ${file}: ${arg_name} ${current} -> ${value}"
  perl -0pi -e "s/^ARG ${arg_name}=.*\$/ARG ${arg_name}=${value}/m" "$file"
}

update_arg "caddy/Dockerfile" "CADDY_VERSION" "$(github_latest_tag 'caddyserver/caddy')"
update_arg "dashy/Dockerfile" "DASHY_VERSION" "$(github_latest_tag 'Lissy93/dashy')"
update_arg "plex/Dockerfile" "PLEX_VERSION" "$(plex_latest_version)"
update_arg "prowlarr/Dockerfile" "PROWLARR_VERSION" "$(strip_v "$(github_latest_tag 'Prowlarr/Prowlarr')")"
update_arg "radarr/Dockerfile" "RADARR_VERSION" "$(strip_v "$(github_latest_tag 'Radarr/Radarr')")"
update_arg "sonarr/Dockerfile" "SONARR_VERSION" "$(strip_v "$(github_latest_tag 'Sonarr/Sonarr')")"
update_arg "syncthing/Dockerfile" "SYNCTHING_VERSION" "$(github_latest_tag 'syncthing/syncthing')"
update_arg "transmission/Dockerfile" "TRANSMISSION_VERSION" "$(strip_v "$(github_latest_tag 'transmission/transmission')")"
update_arg "wireguard-ui/Dockerfile" "WG_UI_VERSION" "$(github_latest_tag 'ngoduykhanh/wireguard-ui')"