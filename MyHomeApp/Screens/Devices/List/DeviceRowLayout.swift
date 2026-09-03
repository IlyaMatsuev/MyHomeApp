import Foundation
import AnyCodable

/// Decides which of a device's config items are worth a spot in the list row.
///
/// Everything a device can do lives in its sheet; the row only promotes the handful of items people
/// reach for constantly. The names match the hub's device configs (`configs/devices/*.yaml`).
enum DeviceRowLayout {
    static let controlNames: Set<String> = ["on", "brightness"]
    static let commandNames: Set<String> = ["text"]

    static func controlItems(of device: Device) -> [DeviceConfigItem] {
        device.controlItems.filter { controlNames.contains($0.name) && $0.isEditable }
    }

    static func commandItems(of device: Device) -> [DeviceConfigItem] {
        device.commandItems.filter { commandNames.contains($0.name) && $0.isEditable }
    }

    /// A single read-only line summarising every measurement the device reports.
    static func measurementsSummary(of device: Device) -> String? {
        let parts = device.measurementItems.compactMap { item -> String? in
            guard let value = device.measurementValue(of: item), !(value.value is NSNull) else { return nil }
            return "\(item.label) \(DeviceConfigValue.text(of: value, for: item))"
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
