# SmartHome App (IOS)

iOS client for the [MySmartHome](https://github.com/IlyaMatsuev/MySmartHome) hub. Built with SwiftUI.

**Download page:** <https://ilyamatsuev.github.io/SmartHomeAppIOS/>

![My Home Banner](./public/banner.png)

## Requirements

- **Xcode** 26.x
- **iOS** 18.6+ (deployment target)
- **Swift** 5.0
- **macOS** with Apple Silicon recommended

## Setup

1. Clone the repo and open `SmartHomeAppIOS.xcodeproj` in Xcode.
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
xcodebuild build -scheme SmartHomeAppIOS -destination 'platform=iOS Simulator,name=iPhone 13 mini'

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
xcodebuild test -scheme SmartHomeAppIOS -destination 'platform=iOS Simulator,name=iPhone 13 mini' -testPlan UnitTests

# Everything, including UI tests
xcodebuild test -scheme SmartHomeAppIOS -destination 'platform=iOS Simulator,name=iPhone 13 mini' -testPlan AllTests

# A single test method
xcodebuild test \
  -scheme SmartHomeAppIOS \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini' \
  -testPlan UnitTests \
  -only-testing:SmartHomeAppIOSTests/DevicesViewModelTests/loadGroupsDevicesByRoom
```

Unit tests live in `SmartHomeAppIOSTests/` and use [Swift Testing](https://developer.apple.com/documentation/testing) (`@Test`, `#expect`).

UI tests live in `SmartHomeAppIOSUITests/` and use XCTest / XCUITest.

## Linting

[SwiftLint](https://github.com/realm/SwiftLint) runs automatically during builds via a Swift Package Plugin and surfaces warnings inline in Xcode. To run it manually:

```bash
# Lint the whole project
swiftlint

# Auto-fix what it can
swiftlint --fix
```

## SideStore

The app is sideloaded via [SideStore](https://sidestore.io). Free Apple ID; SideStore re-signs on-device.

### Anisette servers list

[sidestore-anisette-servers.json](sidestore-anisette-servers.json) - entry 1 is the self-hosted server from [docker-compose.yaml](docker-compose.yaml), rest are community fallbacks.

Host it as a **secret gist** on <https://gist.github.com> with filename `sidestore-anisette-servers.json`. Copy the **Raw** URL and paste it in SideStore → Settings → **Anisette Servers**.

To update: edit both the file in this repo and the gist (keep the same filename so the raw URL is stable), then refresh in SideStore.

### GitHub setup

Releases are published as GitHub Releases via a manual workflow. SideStore subscribes to [docs/apps.json](docs/apps.json) served by GitHub Pages and pulls new versions.

1. Repo Settings → **Pages** → source = branch `main`, folder `/docs`.
2. Repo Settings → **Actions → General** → *Workflow permissions* = **Read and write**.

### iPhone setup & app installation

1. Install SideStore per <https://sidestore.io/#get-started>.
2. SideStore → **Settings** → **Account** → sign in with an [app-specific password](https://support.apple.com/en-us/HT204397). Not your real Apple ID password.
3. Paste the anisette gist raw URL into Settings → **Anisette Servers** and pick the local server as default.
4. SideStore → **Sources** → **+** → `https://ilyamatsuev.github.io/SmartHomeAppIOS/apps.json`.
5. Open the source → **MyHome** → **Free Download**.

### Publishing a app new version

Publishing a new version:

1. GitHub → **Actions** → **Release IPA** → **Run workflow**. Enter a version like `1.2.0` and optional notes.
2. On the phone: SideStore → **My Apps** → pull to refresh. Tap **Update**.

Workflow: [.github/workflows/release.yaml](.github/workflows/release.yaml). Manual only (`workflow_dispatch`).

### App Auto-refresh

Free-signed apps expire every 7 days. To re-sign in the background:

1. iOS **Settings → General → Background App Refresh** — global toggle on, SideStore enabled.
2. SideStore → Settings → **Background Refresh** — enabled, daily interval.
3. Keep SideStore's WireGuard VPN profile enabled — the on-device signing loopback needs it.

Manual refresh: SideStore → **My Apps** → pull to refresh.

## License

[PolyForm Noncommercial](LICENSE)
