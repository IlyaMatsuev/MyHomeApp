#!/usr/bin/env bash
#
# install_on_device.sh — build My Home and install it on a paired iPhone,
# from a Mac, without opening Xcode.
#
# Re-running this is also the refresh: a free Apple ID signs for 7 days, and
# every run renews the provisioning profile and reinstalls the app.
#
# One-time setup:
#   - Add your Apple ID in Xcode → Settings → Accounts. -allowProvisioningUpdates
#     signs with the credentials stored there, and there's no CLI equivalent for
#     adding the account.
#   - Pair the iPhone with this Mac. `xcrun devicectl list devices` has to list
#     it; if you also tick "Connect via network" in Xcode → Window → Devices,
#     no cable is needed here at all.
#
# Usage:
#   scripts/install_on_device.sh                      # first paired iPhone
#   scripts/install_on_device.sh -d "Ilya Matsuev"    # pick by name/UDID
#   scripts/install_on_device.sh -c Debug             # faster build
#   scripts/install_on_device.sh -l                   # list devices and exit
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO_ROOT/MyHomeApp.xcodeproj"
SCHEME="MyHomeApp"
CONFIGURATION="Release"
DEVICE=""
# Outside the repo, so it survives cleans and stays out of git. Keeping it
# separate from Xcode's own derived data means the GUI and this script don't
# invalidate each other's incremental builds.
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData/MyHomeApp-device"

usage() {
  sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

list_only=false
while getopts ":d:c:lh" opt; do
  case "$opt" in
    d) DEVICE="$OPTARG" ;;
    c) CONFIGURATION="$OPTARG" ;;
    l) list_only=true ;;
    h) usage; exit 0 ;;
    :) echo "Error: -$OPTARG requires an argument." >&2; exit 1 ;;
    \?) echo "Error: unknown option -$OPTARG." >&2; exit 1 ;;
  esac
done

if ! xcrun --find devicectl >/dev/null 2>&1; then
  echo "Error: devicectl not found - needs Xcode 15 or newer." >&2
  exit 1
fi

devices_json="$(mktemp)"
trap 'rm -f "$devices_json"' EXIT
xcrun devicectl list devices --json-output "$devices_json" >/dev/null

# devicectl reports both a CoreDevice identifier and the real UDID; xcodebuild
# destinations only understand the UDID, so key everything off that.
read_devices() {
  python3 - "$devices_json" "$DEVICE" <<'PY'
import json, sys

path, want = sys.argv[1], sys.argv[2].lower()
devices = json.load(open(path))["result"]["devices"]

for dev in devices:
    hw = dev.get("hardwareProperties", {})
    if hw.get("platform") != "iOS":
        continue
    udid = hw.get("udid", "")
    name = dev.get("deviceProperties", {}).get("name", "")
    state = dev.get("connectionProperties", {}).get("pairingState", "")
    if want and want not in name.lower() and want not in udid.lower():
        continue
    print("\t".join([udid, name, state]))
PY
}

if [[ "$list_only" == true ]]; then
  echo "Paired iOS devices:"
  read_devices | while IFS=$'\t' read -r udid name state; do
    printf '  %-26s %s (%s)\n' "$udid" "$name" "$state"
  done
  exit 0
fi

device_line="$(read_devices | head -n1)"
if [[ -z "$device_line" ]]; then
  echo "Error: no paired iPhone found${DEVICE:+ matching '$DEVICE'}." >&2
  echo "  Connect it by USB once and trust this Mac, then re-check with:" >&2
  echo "    scripts/install_on_device.sh -l" >&2
  exit 1
fi

IFS=$'\t' read -r UDID DEVICE_NAME PAIRING_STATE <<<"$device_line"
echo "==> Device: $DEVICE_NAME ($UDID, $PAIRING_STATE)"

echo "==> Building $SCHEME ($CONFIGURATION)..."
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS,id=$UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates

# The .app name doesn't have to match the scheme, so take whatever was built
# rather than assuming.
products_dir="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphoneos"
app="$(find "$products_dir" -maxdepth 1 -name '*.app' -print -quit 2>/dev/null || true)"
if [[ -z "$app" ]]; then
  echo "Error: no .app in $products_dir." >&2
  exit 1
fi

echo "==> Installing $(basename "$app")..."
xcrun devicectl device install app --device "$UDID" "$app"

echo "==> Done. Signed for 7 days - re-run this to refresh."
