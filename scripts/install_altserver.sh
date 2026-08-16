#!/usr/bin/env bash
#
# Installs AltServer with all the necessary tools
#
# Runs `docker compose up` for the altserver container (see docker-compose.yaml),
# then install_netmuxd.sh to replace the image's broken netmuxd binary and
# install_ios26_signer.sh to replace AltServer with an iOS 26 compatible build.
# Run once on the linux server
#
# Usage:
#   sudo scripts/install_altserver.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not on PATH." >&2
  exit 1
fi

echo "==> Starting AltServer container..."
(cd "$REPO_ROOT" && docker compose up -d --build --force-recreate)

echo "==> Installing netmuxd..."
"$SCRIPT_DIR/install_netmuxd.sh"

echo "==> Installing the iOS 26 signer (patched AltServer + rcodesign)..."
"$SCRIPT_DIR/install_ios26_signer.sh"

echo "==> AltServer is up. Pair a device with:"
echo "    scripts/install_altstore.sh -a <apple-id> -p \"<password>\""
