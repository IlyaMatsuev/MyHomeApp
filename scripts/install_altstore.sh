#!/usr/bin/env bash
#
# install_altstore.sh — pair a connected iPhone and install AltStore through the dockerized AltServer-Linux container

set -euo pipefail

CONTAINER="altserver"
IPA_PATH="/altserver/bin/AltStore.ipa"

APPLE_ID=""
PASSWORD=""
UDID=""

usage() {
  cat <<'EOF'
Pair a connected iPhone and install AltStore

Usage:
  scripts/install_altstore.sh -a <apple-id> -p <password> [-u <device-udid>]

  -a  Apple ID (email) used to sign AltStore   Required
  -p  Apple ID password                        Required (prompted if omitted)
  -u  Device UDID                              Optional - auto-detected from the first connected iPhone
  -h  Show this help

AltServer prompts on this terminal for a two-factor code, so run it interactively.
EOF
}

find_udid_hint() {
  cat >&2 <<EOF
Find the UDID via the AltServer container (that's where usbmuxd runs):
  docker exec $CONTAINER idevice_id -l
Then pass it explicitly:  scripts/install_altstore.sh -a <apple-id> -u <udid>
EOF
}

while getopts ":a:p:u:h" opt; do
  case "$opt" in
    a) APPLE_ID="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    u) UDID="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Error: -$OPTARG requires an argument." >&2; usage; exit 1 ;;
    \?) echo "Error: unknown option -$OPTARG." >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$APPLE_ID" ]]; then
  echo "Error: -a <apple-id> is required." >&2
  usage
  exit 1
fi

# Prompt for the password if not passed, so it stays out of shell history
if [[ -z "$PASSWORD" ]]; then
  read -r -s -p "Apple ID password: " PASSWORD
  echo
  [[ -z "$PASSWORD" ]] && { echo "Error: password is required." >&2; exit 1; }
fi

# Make sure the AltServer container is up — we detect and pair through it.
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Error: container '$CONTAINER' is not running. Start it with:" >&2
  echo "  sudo scripts/install_altserver.sh" >&2
  exit 1
fi

# The stock AltServer signs with ldid, whose signature iOS 26 rejects - the
# install reports success and the app crashes instantly on launch. Installing
# the signer is install_altserver.sh's job; this just refuses to sign with a
# setup that would produce a broken app.
signer_problem=""
if ! docker exec "$CONTAINER" test -x /altserver/bin/rcodesign; then
  signer_problem="rcodesign is missing from the container"
elif ! docker exec "$CONTAINER" printenv ALTSERVER_RCODESIGN >/dev/null 2>&1; then
  signer_problem="ALTSERVER_RCODESIGN is unset - the container predates it and needs a recreate"
elif ! docker exec "$CONTAINER" sh -c 'command -v openssl >/dev/null 2>&1'; then
  signer_problem="openssl is missing from the container"
fi

if [[ -n "$signer_problem" ]]; then
  echo "Error: $signer_problem." >&2
  echo "  Apps signed without it install fine and crash instantly on iOS 26." >&2
  echo "  Set the signer up, then re-run this:" >&2
  echo "    sudo scripts/install_altserver.sh" >&2
  exit 1
fi

# Auto-detect the device UDID when -u is not given. usbmuxd runs inside the
# container (the host has none), so ask the container, not the host.
if [[ -z "$UDID" ]]; then
  UDID="$(docker exec "$CONTAINER" idevice_id -l 2>/dev/null | head -n1 || true)"

  if [[ -z "$UDID" ]]; then
    echo "Error: no iPhone detected by the '$CONTAINER' container." >&2
    echo "  - Use a data USB cable (not charge-only) straight into the server (no hubs)." >&2
    echo "  - Unlock the phone and tap \"Trust This Computer\" (enter passcode)." >&2
    echo "  - Re-check with: docker exec $CONTAINER idevice_id -l" >&2
    find_udid_hint
    exit 1
  fi

  if [[ "$(docker exec "$CONTAINER" idevice_id -l 2>/dev/null | grep -c .)" -gt 1 ]]; then
    echo "Warning: multiple devices connected; using the first: $UDID" >&2
    echo "         Pass -u <device-udid> to target a specific one." >&2
  fi
fi

echo "Pairing and installing AltStore on device: $UDID"

docker exec -it "$CONTAINER" \
  /altserver/bin/AltServer -u "$UDID" -a "$APPLE_ID" -p "$PASSWORD" "$IPA_PATH"
