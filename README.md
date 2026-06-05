# SmartHome App (IOS)

iOS client for the [MySmartHome](https://github.com/IlyaMatsuev/MySmartHome) hub. Built with SwiftUI.

## Requirements

- **Xcode** 26.x
- **iOS** 18.6+ (deployment target)
- **Swift** 5.0
- **macOS** with Apple Silicon recommended

## Setup

1. Clone the repo and open `SmartHomeAppIOS.xcodeproj` in Xcode.
2. Install developer tools (one-time):

```bash
brew install swiftlint
```

3. Wait for Xcode to resolve Swift Package Manager dependencies on first open.

Dependencies are managed through SPM and pinned in `Package.resolved`. No CocoaPods or Carthage.

## Running the app

In Xcode: pick an iPhone simulator (iOS 18.x or 26.x) and press `Cmd+R`.

From the command line:

```bash
# Build
xcodebuild build -scheme SmartHomeAppIOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Discover available simulators
xcrun simctl list devices available
```

Substitute `iPhone 17 Pro` with whatever simulator you have installed.

## Running tests

Inside Xcode: `Cmd+U` runs all tests. `Ctrl+Opt+Cmd+U` runs the test under the cursor.

From the command line:

```bash
# Full suite
xcodebuild test -scheme SmartHomeAppIOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# A single test method
xcodebuild test \
  -scheme SmartHomeAppIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
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

## License

[PolyForm Noncommercial](LICENSE)
