# My Home App (iOS)

iOS client for the [My Home Hub](https://github.com/IlyaMatsuev/MyHomeHub). Built with SwiftUI.

**Download page:** <https://ilyamatsuev.github.io/MyHomeApp/>

![My Home Banner](./docs/assets/banner.png)

## Requirements

- **Xcode** 26.x
- **iOS** 18.6+ (deployment target)
- **Swift** 5.0
- **macOS** with Apple Silicon recommended

## Setup

1. Clone the repo and open `MyHomeApp.xcodeproj` in Xcode.
2. Copy [Local.xcconfig.example](Local.xcconfig.example) to `Local.xcconfig` and set your values:

```bash
cp Local.xcconfig.example Local.xcconfig
```

3. Install developer tools (one-time):

```bash
brew install swiftlint
```

4. Wait for Xcode to resolve Swift Package Manager dependencies on first open.

Dependencies are managed through SPM and pinned in `Package.resolved`. No CocoaPods or Carthage.

## Running the app

In Xcode: pick an iPhone simulator (iOS 18.x or 26.x) and press `Cmd+R`.

From the command line:

```bash
# Build
xcodebuild build -scheme MyHomeApp -destination 'platform=iOS Simulator,name=iPhone 13 mini'

# Discover available simulators
xcrun simctl list devices available
```

Substitute `iPhone 13 mini` with whatever simulator you have installed.

## Running tests

The scheme ships two test plans: **UnitTests** (default — unit tests only, fast) and **AllTests** (unit + UI tests).

Inside Xcode: `Cmd+U` runs the default plan (UnitTests). `Ctrl+Opt+Cmd+U` runs the test under the cursor. Switch plans from the Test Navigator's plan selector or `Product → Test Plan`.

From the command line:

```bash
# Unit tests (fast — no UI tests)
xcodebuild test -scheme MyHomeApp -destination 'platform=iOS Simulator,name=iPhone 13 mini' -testPlan UnitTests

# Everything, including UI tests
xcodebuild test -scheme MyHomeApp -destination 'platform=iOS Simulator,name=iPhone 13 mini' -testPlan AllTests

# A single test method
xcodebuild test \
  -scheme MyHomeApp \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini' \
  -testPlan UnitTests \
  -only-testing:MyHomeAppTests/DevicesViewModelTests/loadGroupsDevicesByRoom
```

Unit tests live in `MyHomeAppTests/` and use [Swift Testing](https://developer.apple.com/documentation/testing) (`@Test`, `#expect`).

UI tests live in `MyHomeAppUITests/` and use XCTest / XCUITest.

## Linting

[SwiftLint](https://github.com/realm/SwiftLint) runs automatically during builds via a Swift Package Plugin and surfaces warnings inline in Xcode. To run it manually:

```bash
# Lint the whole project
swiftlint

# Auto-fix what it can
swiftlint --fix
```

## AltStore

The app is sideloaded via [AltStore](https://altstore.io). [AltServer-Linux](https://github.com/NyaMisty/AltServer-Linux) should be installed on an ubuntu server in the same network as other devices.

### AltServer setup & app installation

Run once on the always-on Linux server:

1. Install the AltServer:

```bash
sudo scripts/install_altserver.sh
```

2. Connect the phone by USB for the first pairing, then run the pairing script:

```bash
scripts/install_altstore.sh -a <apple-id> -p "<password>"
```

A dedicated sideloading Apple ID is recommended; you'll be prompted for a 2FA code.

3. On the phone: open **AltStore → Settings** → sign in with the same Apple ID.

4. AltStore → **Sources** → **+** → `https://ilyamatsuev.github.io/MyHomeApp/apps.json`.
5. Open the source → **My Home**

### If the phone isn't detected

The one-time USB pairing is the only fussy part. AltServer reaches the phone through the container's `usbmuxd`; if `install_altstore.sh` can't find the device, work through these in order:

1. **Use a real data cable, plugged straight into the server** — no hubs, docks, or extension cables. A charge-only or failing cable is the most common cause: the phone shows up in `lsusb` and even reports its serial, but `lockdownd` pairing fails (`lockdown error -8` in the logs). Swapping the cable/port fixes this more often than anything else.
2. **Unlock the phone and tap "Trust This Computer"** (enter the passcode). iOS blocks USB data while the phone is locked, so keep the screen unlocked throughout pairing.
3. **Verify the container sees the phone:**

```bash
# prints the device UDID
docker exec altserver idevice_id -l         
# prints SUCCESS once trusted
docker exec altserver idevicepair validate
```

If `idevice_id -l` is empty, re-seat (or swap) the cable, re-enumerate, and give it a few seconds:

```bash
docker exec altserver supervisorctl restart usbmuxd && sleep 15 && docker exec altserver idevice_id -l
```

> Note: the container runs its **own** `usbmuxd` (visible on the host as `usbmuxd -f -v`). That's expected - don't kill it. USB access is granted by the `device_cgroup_rules` entry in [docker-compose.yaml](docker-compose.yaml); without it `usbmuxd` can see the phone but can't open it (`errno=1`).

Once `idevicepair validate` returns `SUCCESS`, run `install_altstore.sh`. The pairing record persists on the server (`/var/lib/lockdown`), so after this one-time USB step every future refresh happens over Wi-Fi — no cable needed.

### If the app installs but crashes on launch (iOS 26)

Upstream AltServer-Linux signs with a vendored `ldid` from ~2022. On **iOS 26.4+** the kernel's TXM rejects that signature, so the install reports `Installation Succeeded` and the app dies instantly on launch with no crash report ([AltServer-Linux#131](https://github.com/NyaMisty/AltServer-Linux/issues/131)). The rejected parts are ldid's DER entitlements schema, its SHA-1-primary CodeDirectory, its empty designated requirements, and its old CodeResources format.

[install_ios26_signer.sh](scripts/install_ios26_signer.sh) fixes this by installing a [patched AltServer](https://github.com/ondrej-simon/AltServer-Linux) that signs with [`rcodesign`](https://github.com/indygreg/apple-platform-rs) instead of ldid - everything else (Apple auth, certificate, provisioning, install) is unchanged. `install_altserver.sh` runs it, so **repairing an existing setup is the normal two-step setup above** — re-run it, then pair again:

```bash
sudo scripts/install_altserver.sh
scripts/install_altstore.sh -a <apple-id> -p "<password>"
```

Delete AltStore from the phone first. AltServer signs every app it installs and refreshes, so this applies to **My Home** too — an app installed through a broken AltServer keeps crashing until it's re-signed by the patched one.

Confirm the container picked it up - the install log should print `rcodesign signing: ...`:

```bash
docker exec altserver /altserver/bin/rcodesign --version
```

### GitHub setup

Releases are published as GitHub Releases via a manual workflow. AltStore subscribes to [`https://ilyamatsuev.github.io/MyHomeApp/apps.json`](https://ilyamatsuev.github.io/MyHomeApp/apps.json) - an AltStore source served by GitHub Pages — and pulls new versions.

1. Repo Settings → **Pages** → source = branch `main`, folder `/docs`.
2. Repo Settings → **Actions → General** → *Workflow permissions* = **Read and write**.

### Publishing a new app version

1. GitHub → **Actions** → **Release IPA** → **Run workflow**. Enter a version like `1.2.0` and optional notes.
2. On the phone: AltStore → **My Apps** → pull to refresh. Tap **Update**.

Workflow: [.github/workflows/release.yaml](.github/workflows/release.yaml). Manual only (`workflow_dispatch`).

## License

[PolyForm Noncommercial](LICENSE)
