import Foundation

/// Field constraints the hub enforces on a device.
///
/// Mirrors `src/devices/devices.constants.ts` and `src/common/common.constants.ts` in the hub. The
/// copy exists only to spare the user a round trip — the hub stays the authority.
enum DeviceLimits {
    static let nameLength = 3...40
    static let zigbeeFriendlyNameLength = 3...60

    /// `ZIGBEE_FRIENDLY_NAME_REGEX` — word characters and inner spaces.
    static let zigbeeFriendlyNamePattern = /^\w(?:[\w ]*\w)?$/

    /// `DEVICE_DEFAULT_UPDATE_INTERVAL` — the hub's minimum update interval, in milliseconds.
    static let minUpdateInterval = 0
}
