import Foundation
import AnyCodable

/// Reads, formats and checks a single command/control/measurement value against its config item.
///
/// The validation here mirrors `validateItemValue` in the hub
/// (`src/device-configs/validators/device-config-item.validators.ts`) — it exists only to spare the
/// user a round trip, so it must stay in step with that file. The hub remains the authority.
enum DeviceConfigValue {
    // MARK: - Reading

    static func bool(_ value: AnyCodable?) -> Bool? {
        value?.value as? Bool
    }

    static func number(_ value: AnyCodable?) -> Double? {
        switch value?.value {
        case let double as Double: return double
        case let int as Int: return Double(int)
        case let float as Float: return Double(float)
        default: return nil
        }
    }

    static func string(_ value: AnyCodable?) -> String? {
        value?.value as? String
    }

    // MARK: - Formatting

    /// Human-readable rendering of a stored value, resolving enum names to their labels.
    static func text(of value: AnyCodable?, for item: DeviceConfigItem) -> String {
        guard let value, !(value.value is NSNull) else { return "—" }

        switch item.type {
        case .boolean:
            return bool(value) == true ? "On" : "Off"

        case .number:
            return number(value).map { format($0, integer: item.constraints?.integer == true) } ?? text(of: value)

        case .enumeration:
            return item.optionLabel(forName: string(value) ?? text(of: value))

        case .string, .object, .unsupported:
            return text(of: value)
        }
    }

    /// Rendering of a value with no config item behind it.
    static func text(of value: AnyCodable?) -> String {
        switch value?.value {
        case nil, is NSNull: return "—"
        case let bool as Bool: return bool ? "On" : "Off"
        case let int as Int: return String(int)
        case let double as Double: return format(double, integer: false)
        case let string as String: return string
        case let other?: return String(describing: other)
        }
    }

    /// Two decimals at most, with trailing zeros trimmed: `27.5`, not `27.50`.
    static func format(_ number: Double, integer: Bool) -> String {
        if integer || number == number.rounded() {
            return String(Int(number.rounded()))
        }

        var text = String(format: "%.2f", number)
        while text.hasSuffix("0") {
            text.removeLast()
        }
        if text.hasSuffix(".") {
            text.removeLast()
        }
        return text
    }

    // MARK: - Validation

    /// A message describing why `value` violates the item's rules, or `nil` when it passes.
    static func error(for item: DeviceConfigItem, value: AnyCodable?) -> String? {
        guard let value, !(value.value is NSNull) else { return nil }

        switch item.type {
        case .boolean:
            return bool(value) == nil ? "\(item.label) must be on or off." : nil

        case .number:
            return numberError(for: item, value: value)

        case .string:
            return stringError(for: item, value: value)

        case .enumeration:
            return enumerationError(for: item, value: value)

        case .object, .unsupported:
            return nil
        }
    }

    private static func numberError(for item: DeviceConfigItem, value: AnyCodable) -> String? {
        guard let number = number(value) else { return "\(item.label) must be a number." }

        let constraints = item.constraints
        if constraints?.integer == true, number != number.rounded() {
            return "\(item.label) must be a whole number."
        }
        if let min = constraints?.min, number < min {
            return "\(item.label) must not be less than \(format(min, integer: constraints?.integer == true))."
        }
        if let max = constraints?.max, number > max {
            return "\(item.label) must not be greater than \(format(max, integer: constraints?.integer == true))."
        }
        return nil
    }

    private static func stringError(for item: DeviceConfigItem, value: AnyCodable) -> String? {
        guard let string = string(value) else { return "\(item.label) must be text." }

        let constraints = item.constraints
        if let minLength = constraints?.minLength, string.count < minLength {
            return "\(item.label) must be at least \(minLength) characters."
        }
        if let maxLength = constraints?.maxLength, string.count > maxLength {
            return "\(item.label) must be at most \(maxLength) characters."
        }
        if let pattern = constraints?.pattern, string.range(of: pattern, options: .regularExpression) == nil {
            return "\(item.label) must match \(pattern)."
        }
        if let format = constraints?.format, !matches(format: format, string) {
            return "\(item.label) must be a valid \(format.label) value."
        }
        return nil
    }

    private static func enumerationError(for item: DeviceConfigItem, value: AnyCodable) -> String? {
        let allowed = item.options.map(\.name)
        guard !allowed.isEmpty else {
            return string(value) == nil ? "\(item.label) must be text." : nil
        }
        guard let string = string(value), allowed.contains(string) else {
            return "\(item.label) must be one of: \(item.options.map(\.label).joined(separator: ", "))."
        }
        return nil
    }

    /// Formats the app knows how to check. An unknown one is left to the hub.
    private static func matches(format: DeviceConfigItemFormat, _ string: String) -> Bool {
        switch format {
        case .hexColor:
            return string.isHexColor

        case .ipAddress:
            return string.isIPv4Address

        case .url:
            return URL(string: string)?.scheme != nil

        case .unsupported:
            return true
        }
    }
}
