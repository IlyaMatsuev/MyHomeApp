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

1. Pull AltServer container with netmuxd (used for Wi-Fi refresh):

```bash
docker compose up -d --build
```

2. Connect the phone by USB for the first pairing, then run the pairing script:

```bash
scripts/pair_device.sh -a <apple-id> -p "<password>"
```

A dedicated sideloading Apple ID is recommended; you'll be prompted for a 2FA code.

3. On the phone: open **AltStore → Settings** → sign in with the same Apple ID.

4. AltStore → **Sources** → **+** → `https://ilyamatsuev.github.io/MyHomeApp/apps.json`.
5. Open the source → **My Home**

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
