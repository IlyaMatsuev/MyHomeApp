# Mocks

Hand-rolled mocks and fixtures for unit tests.

## Conventions

- **One mock per protocol.** Filename: `Mock<ProtocolName>.swift` (e.g. `MockDevicesService.swift`).
- **Conform to the production protocol exactly** so the compiler keeps the mock honest.
- **Expose stubbed results as properties**: `var fetchAllResult: Result<[Device], Error> = .success([])`.
- **Record calls**: `private(set) var fetchAllCallCount = 0` and `private(set) var updateReceived: [Device] = []`.
- **No XCTest imports in mocks.** Keep them pure types so they can be reused from anywhere.

## Fixtures

Model fixtures live next to mocks as extensions:

```swift
// Device+Fixture.swift
extension Device {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Test Device",
        kind: DeviceKind = .light,
        isOnline: Bool = true
    ) -> Device {
        Device(id: id, name: name, kind: kind, isOnline: isOnline)
    }
}
```

Default every parameter so each test only overrides what it cares about.

## Adding files to Xcode

Files in this folder are NOT automatically part of the `SmartHomeAppIOSTests` target.
After creating a new mock or fixture:

1. Drag the file from Finder into the `SmartHomeAppIOSTests/Mocks` group in Xcode.
2. In the dialog, check **only** `SmartHomeAppIOSTests` under "Add to targets".
3. Do **not** add it to the main app target or the UI test target.
