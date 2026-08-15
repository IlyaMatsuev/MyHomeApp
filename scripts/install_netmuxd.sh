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
#   status 127 (FATAL). This script fetches a correct release binary for the
#   host CPU and drops it in ./bin/netmuxd, which the mounted volume feeds to
#   the container. The image only re-downloads netmuxd when the file is missing,
#   so this replacement persists across restarts.
#
# Why a pinned version (not "latest"):
#   The dreth image is built on `debian:bookworm-slim` (glibc 2.36), but every
#   netmuxd release from v0.3.0 onward is compiled against glibc 2.38, so
#   "latest" loads but crashes at startup with:
#     libc.so.6: version `GLIBC_2.38' not found ... (exit status 1)
#   v0.2.1-try1 is the newest release that still links against <= glibc 2.36
#   (it needs 2.34), so it's the newest netmuxd that runs on this base image.
#   Bump NETMUXD_VERSION only if the container's base image ships a newer glibc.
#
# Usage:
#   scripts/install_netmuxd.sh
#
# Overrides (values from https://github.com/jkcoxson/netmuxd/releases):
#   NETMUXD_VERSION=v0.3.0 scripts/install_netmuxd.sh
#   NETMUXD_TRIPLE=aarch64-unknown-linux-gnu scripts/install_netmuxd.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$REPO_ROOT/bin"
CONTAINER="altserver"
NETMUXD_VERSION="${NETMUXD_VERSION:-v0.2.1-try1}"

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

echo "Host arch: $(uname -m) → netmuxd $NETMUXD_VERSION ($TRIPLE)"

url="https://github.com/jkcoxson/netmuxd/releases/download/${NETMUXD_VERSION}/netmuxd-${TRIPLE}.tar.gz"

echo "Downloading: $url"
mkdir -p "$BIN_DIR"

# Extract to a temp file in the same dir, then atomically replace. Rename works
# even while the container is currently executing the old netmuxd (it keeps the
# old inode until it restarts), and it makes re-runs idempotent — extracting in
# place would fail because the file already exists / is busy.
tmp="$(mktemp "$BIN_DIR/netmuxd.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$url" | tar -xzO netmuxd > "$tmp"
chmod +x "$tmp"
mv -f "$tmp" "$BIN_DIR/netmuxd"
echo "Installed: $BIN_DIR/netmuxd"

# Restart the container so supervisord picks up the new binary.
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Restarting '$CONTAINER'…"
  (cd "$REPO_ROOT" && docker compose restart "$CONTAINER")
  echo "Done."
else
  echo "Container '$CONTAINER' is not running yet - start it with:"
  echo "  docker compose up -d --build"
fi
