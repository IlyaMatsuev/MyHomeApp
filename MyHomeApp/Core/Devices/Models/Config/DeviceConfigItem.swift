import Foundation
import AnyCodable

/// Metadata of a single device command, control or measurement.
///
/// Mirrors `DeviceConfigItem` in the hub (`src/device-configs/interfaces`). The app renders an
/// editor from `type` + `constraints` + `values` rather than hardcoding a layout per device.
struct DeviceConfigItem: Codable, Hashable, Identifiable {
    let label: String
    let name: String
    let type: DeviceConfigItemType
    let description: String?
    let path: String?
    let required: Bool?
    let constraints: DeviceConfigItemConstraints?
    // swiftlint:disable:next discouraged_optional_collection
    let values: [DeviceConfigItemOption]?
    let defaultValue: AnyCodable?

    var id: String { name }

    init(
        label: String,
        name: String,
        type: DeviceConfigItemType,
        description: String? = nil,
        path: String? = nil,
        required: Bool? = nil,
        constraints: DeviceConfigItemConstraints? = nil,
        // swiftlint:disable:next discouraged_optional_collection
        values: [DeviceConfigItemOption]? = nil,
        defaultValue: AnyCodable? = nil
    ) {
        self.label = label
        self.name = name
        self.type = type
        self.description = description
        self.path = path
        self.required = required
        self.constraints = constraints
        self.values = values
        self.defaultValue = defaultValue
    }

    private enum CodingKeys: String, CodingKey {
        case label
        case name
        case type
        case description
        case path
        case required
        case constraints
        case values
        case defaultValue = "default"
    }
}

extension DeviceConfigItem {
    var options: [DeviceConfigItemOption] { values ?? [] }

    var isEditable: Bool { type.isEditable }

    /// Label of the option matching `name`, falling back to the raw name for a value the config
    /// doesn't list.
    func optionLabel(forName name: String) -> String {
        options.first { $0.name == name }?.label ?? name
    }

    /// A sensible starting value for an editor when the device has no value stored yet.
    var fallbackValue: AnyCodable {
        if let defaultValue { return defaultValue }

        switch type {
        case .boolean:
            return AnyCodable(false)

        case .number:
            return AnyCodable(constraints?.min ?? 0)

        case .enumeration:
            return AnyCodable(options.first?.name ?? "")

        case .string, .object, .unsupported:
            return AnyCodable("")
        }
    }
}

// MARK: - Inference

extension DeviceConfigItem {
    /// Metadata guessed from a stored payload entry, for a device the hub ships no config for.
    ///
    /// Keeps such a device usable in the app: it still gets a toggle for a boolean and a read-only
    /// row for everything else, just without labels, bounds or descriptions.
    static func inferred(name: String, value: AnyCodable?) -> DeviceConfigItem {
        DeviceConfigItem(label: name.humanized, name: name, type: inferredType(of: value))
    }

    private static func inferredType(of value: AnyCodable?) -> DeviceConfigItemType {
        switch value?.value {
        case is Bool: return .boolean
        case is Int, is Double, is Float: return .number
        case is String: return .string
        default: return .object
        }
    }
}
