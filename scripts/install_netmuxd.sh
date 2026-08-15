#!/usr/bin/env bash
#
# install_netmuxd.sh — install a working netmuxd binary into ./bin for the
# dockerized AltServer stack (see docker-compose.yaml).
#
# Why this exists:
#   The dreth/Altserver-docker image downloads netmuxd from a stale URL
#   (`<arch>-linux-netmuxd`). netmuxd v0.4.x renamed its release assets to
#   `netmuxd-<rust-triple>.tar.gz`, so that old URL 404s — curl saves the
#   "Not Found" page as the binary, and the container's netmuxd exits with
#   status 127 (FATAL). This script fetches the correct release binary for the
#   host CPU and drops it in ./bin/netmuxd, which the mounted volume feeds to
#   the container. The image only re-downloads netmuxd when the file is missing,
#   so this replacement persists across restarts.
#
# Usage:
#   scripts/install_netmuxd.sh
#
# Override the target if auto-detect is wrong (values from netmuxd's releases):
#   NETMUXD_TRIPLE=aarch64-unknown-linux-gnu scripts/install_netmuxd.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$REPO_ROOT/bin"
CONTAINER="altserver"
API="https://api.github.com/repos/jkcoxson/netmuxd/releases/latest"

# Map the host architecture to netmuxd's Rust target triple.
TRIPLE="${NETMUXD_TRIPLE:-}"
if [[ -z "$TRIPLE" ]]; then
  case "$(uname -m)" in
    x86_64|amd64)  TRIPLE="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) TRIPLE="aarch64-unknown-linux-gnu" ;;
    *)
      echo "Error: unsupported architecture '$(uname -m)'." >&2
      echo "Set NETMUXD_TRIPLE to a triple listed at" >&2
      echo "  https://github.com/jkcoxson/netmuxd/releases" >&2
      exit 1
      ;;
  esac
fi

echo "Host arch: $(uname -m) → netmuxd target: $TRIPLE"

# Resolve the matching download URL from the latest release (handles version
# bumps and asset renames without hardcoding a tag).
url="$(curl -fsSL "$API" \
  | grep -o "https://[^\"]*netmuxd-${TRIPLE}[^\"]*\.tar\.gz" \
  | head -n1 || true)"

if [[ -z "$url" ]]; then
  echo "Error: could not find a netmuxd asset for '$TRIPLE' in the latest release." >&2
  echo "Check https://github.com/jkcoxson/netmuxd/releases and set NETMUXD_TRIPLE." >&2
  exit 1
fi

echo "Downloading: $url"
mkdir -p "$BIN_DIR"
curl -fsSL "$url" | tar -xz -C "$BIN_DIR" netmuxd
chmod +x "$BIN_DIR/netmuxd"
echo "Installed: $BIN_DIR/netmuxd"

# Restart the container so supervisord picks up the new binary.
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Restarting '$CONTAINER'…"
  (cd "$REPO_ROOT" && docker compose restart "$CONTAINER")
  echo "Done. Verify with: docker compose logs --tail=20 $CONTAINER | grep -i netmuxd"
else
  echo "Container '$CONTAINER' is not running yet - start it with:"
  echo "  docker compose up -d --build"
fi
