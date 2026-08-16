#!/usr/bin/env bash
#
# install_ios26_signer.sh — install an AltServer that signs apps in a way iOS 26
# accepts, into ./bin for the dockerized AltServer stack (see docker-compose.yaml).
#
# Why this exists:
#   Upstream AltServer-Linux (NyaMisty) signs with a vendored ldid from ~2022.
#   On iOS 26.4+ the kernel's TXM rejects that signature, so an app installs
#   fine ("Installation Succeeded") and then crashes instantly on launch with
#   no crash report. ldid gets four things wrong that iOS 26 now enforces:
#   DER entitlements use the wrong ASN.1 schema, the CodeDirectory is
#   SHA-1-primary instead of SHA-256-only, designated requirements are empty,
#   and CodeResources uses an old resource-sealing format.
#   See https://github.com/NyaMisty/AltServer-Linux/issues/131
#
#   The ondrej-simon fork swaps the ldid::Sign call for a shell-out to
#   rcodesign (apple-codesign); everything else — Apple auth, certificate,
#   provisioning, install — is untouched. rcodesign is not bundled, so this
#   script installs both it and the patched AltServer into ./bin, which the
#   compose file mounts at /altserver/bin. The image only downloads AltServer
#   when the file is missing, so the replacement persists across restarts.
#
#   ALTSERVER_RCODESIGN, set in docker-compose.yaml, is how AltServer finds
#   rcodesign - both for a manual install and for the supervisord daemon that
#   refreshes apps over Wi-Fi. Env changes only reach a container through a
#   recreate, which is why install_altserver.sh is the way to apply this.
#
# Usage:
#   sudo scripts/install_altserver.sh    # runs this as part of setup
#   scripts/install_ios26_signer.sh      # or on its own, to swap the binaries
#
# Overrides (values from the releases pages of the two repos above):
#   ALTSERVER_TAG=v0.0.5-ios26 scripts/install_ios26_signer.sh
#   RCODESIGN_VERSION=0.29.0   scripts/install_ios26_signer.sh
#   ARCH=aarch64               scripts/install_ios26_signer.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$REPO_ROOT/bin"
CONTAINER="altserver"
ALTSERVER_REPO="ondrej-simon/AltServer-Linux"
ALTSERVER_TAG="${ALTSERVER_TAG:-v0.0.5-ios26}"
RCODESIGN_VERSION="${RCODESIGN_VERSION:-0.29.0}"

ARCH="${ARCH:-$(uname -m)}"
case "$ARCH" in
  x86_64|amd64)  ALTSERVER_ASSET="AltServer-x86_64";  RCODESIGN_TRIPLE="x86_64-unknown-linux-musl" ;;
  aarch64|arm64) ALTSERVER_ASSET="AltServer-aarch64"; RCODESIGN_TRIPLE="aarch64-unknown-linux-musl" ;;
  *)
    echo "Error: unsupported architecture '$ARCH'." >&2
    echo "Set ARCH to one matching an asset at" >&2
    echo "  https://github.com/$ALTSERVER_REPO/releases/tag/$ALTSERVER_TAG" >&2
    exit 1
    ;;
esac

echo "Host arch: $ARCH → $ALTSERVER_ASSET ($ALTSERVER_TAG) + rcodesign $RCODESIGN_VERSION"
mkdir -p "$BIN_DIR"

# Read the binary from stdin into a temp file in the same dir, then atomically
# replace. Rename works even while the container is currently executing the old
# binary (it keeps the old inode until it restarts), and it makes re-runs
# idempotent - writing in place would fail because the file is busy.
install_binary() {
  local dest="$1"
  local tmp
  tmp="$(mktemp "$BIN_DIR/$(basename "$dest").XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN
  cat > "$tmp"
  chmod 0755 "$tmp"
  mv -f "$tmp" "$dest"
  echo "Installed: $dest"
}

altserver_url="https://github.com/$ALTSERVER_REPO/releases/download/$ALTSERVER_TAG/$ALTSERVER_ASSET"
echo "Downloading: $altserver_url"
curl -fsSL "$altserver_url" | install_binary "$BIN_DIR/AltServer"

rcodesign_url="https://github.com/indygreg/apple-platform-rs/releases/download/apple-codesign%2F${RCODESIGN_VERSION}/apple-codesign-${RCODESIGN_VERSION}-${RCODESIGN_TRIPLE}.tar.gz"
echo "Downloading: $rcodesign_url"
curl -fsSL "$rcodesign_url" \
  | tar -xzO "apple-codesign-${RCODESIGN_VERSION}-${RCODESIGN_TRIPLE}/rcodesign" \
  | install_binary "$BIN_DIR/rcodesign"

if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  # rcodesign is handed an OpenSSL-converted PEM of AltServer's signing key, so
  # the container needs the openssl CLI, which the base image doesn't ship. It
  # lands in the container layer rather than the ./bin volume, so a recreate
  # takes it out again - hence installing it here, after every recreate.
  if ! docker exec "$CONTAINER" sh -c 'command -v openssl >/dev/null 2>&1'; then
    echo "Installing openssl inside '$CONTAINER'..."
    docker exec "$CONTAINER" sh -c 'apt-get update -qq && apt-get install -y -qq openssl' >/dev/null
  fi

  echo "Restarting '$CONTAINER'..."
  (cd "$REPO_ROOT" && docker compose restart "$CONTAINER")
  echo "Done."
else
  echo "Container '$CONTAINER' is not running yet - start it with:"
  echo "  docker compose up -d --build"
fi
