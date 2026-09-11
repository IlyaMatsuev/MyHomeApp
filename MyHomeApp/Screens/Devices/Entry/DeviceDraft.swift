import Foundation

/// Flat, editable form of a `Device`'s details.
///
/// The wire model is immutable and carries brand/protocol-specific fields that only apply to some
/// devices, so the sheet edits this instead and hands back a `payload` scoped to what still applies.
struct DeviceDraft: Equatable {
    var name: String
    var type: DeviceType
    var brand: DeviceBrand
    var room: DeviceRoom
    var transportProtocol: TransportProtocol

    // swiftlint:disable:next identifier_name
    var ip: String
    var updateInterval: String

    var tuyaDeviceId: String
    var tuyaDeviceLocalKey: String

    var zigbeeFriendlyName: String

    init(device: Device) {
        name = device.name
        type = device.type
        brand = device.brand
        room = device.room
        transportProtocol = device.transportProtocol
        ip = device.ip ?? ""
        updateInterval = device.updateInterval.map(String.init) ?? ""
        tuyaDeviceId = device.tuyaDeviceId ?? ""
        tuyaDeviceLocalKey = device.tuyaDeviceLocalKey ?? ""
        zigbeeFriendlyName = device.zigbeeFriendlyName ?? ""
    }
}

// MARK: - Applicable fields

extension DeviceDraft {
    /// The hub clears brand/protocol-specific fields that no longer apply, so the form hides them
    /// and the payload leaves them out.
    var showsIPField: Bool { transportProtocol == .http || transportProtocol == .tuya }

    var showsTuyaFields: Bool { transportProtocol == .tuya }

    var showsZigbeeFields: Bool { transportProtocol == .zigbee }

    var showsUpdateIntervalField: Bool { transportProtocol != .zigbee }
}

// MARK: - Validation

extension DeviceDraft {
    var isValid: Bool {
        DeviceField.allCases.allSatisfy { error(for: $0) == nil }
    }

    func error(for field: DeviceField) -> String? {
        switch field {
        case .name:
            return nameError

        case .ip:
            return ipError

        case .updateInterval:
            return updateIntervalError

        case .tuyaDeviceId:
            return requiredTuyaError(tuyaDeviceId, label: "Device ID")

        case .tuyaDeviceLocalKey:
            return requiredTuyaError(tuyaDeviceLocalKey, label: "Local key")

        case .zigbeeFriendlyName:
            return zigbeeFriendlyNameError
        }
    }

    /// `true` once the user has overrun a bound, so the field can complain before the first save.
    func exceedsLimit(_ field: DeviceField) -> Bool {
        switch field {
        case .name:
            return name.trimmed.count > DeviceLimits.nameLength.upperBound

        case .zigbeeFriendlyName:
            return zigbeeFriendlyName.trimmed.count > DeviceLimits.zigbeeFriendlyNameLength.upperBound

        case .ip, .updateInterval, .tuyaDeviceId, .tuyaDeviceLocalKey:
            return false
        }
    }

    private var nameError: String? {
        let limits = DeviceLimits.nameLength
        guard limits.contains(name.trimmed.count) else {
            return "Name must be \(limits.lowerBound)–\(limits.upperBound) characters."
        }
        return nil
    }

    private var ipError: String? {
        guard showsIPField, !ip.isBlank else { return nil }
        return ip.trimmed.isIPv4Address ? nil : "Enter a valid IPv4 address, e.g. 192.168.0.10."
    }

    private var updateIntervalError: String? {
        guard showsUpdateIntervalField, !updateInterval.isBlank else { return nil }
        guard let interval = Int(updateInterval.trimmed), interval >= DeviceLimits.minUpdateInterval else {
            return "Update interval must be a whole number of milliseconds, \(DeviceLimits.minUpdateInterval) or more."
        }
        return nil
    }

    private func requiredTuyaError(_ value: String, label: String) -> String? {
        guard showsTuyaFields, value.isBlank else { return nil }
        return "\(label) is required for a Tuya device."
    }

    private var zigbeeFriendlyNameError: String? {
        guard showsZigbeeFields else { return nil }
        let trimmed = zigbeeFriendlyName.trimmed
        let limits = DeviceLimits.zigbeeFriendlyNameLength
        guard limits.contains(trimmed.count) else {
            return "Friendly name must be \(limits.lowerBound)–\(limits.upperBound) characters."
        }
        guard (try? DeviceLimits.zigbeeFriendlyNamePattern.wholeMatch(in: trimmed)) != nil else {
            return "Friendly name may only contain letters, digits, underscores and inner spaces."
        }
        return nil
    }
}

// MARK: - Payload

extension DeviceDraft {
    /// The `PUT /devices/:externalId` body, carrying only fields that apply to the chosen
    /// brand/protocol — the hub clears the rest on its own.
    var payload: DeviceUpdatePayload {
        DeviceUpdatePayload(
            name: name.trimmed,
            type: type,
            brand: brand,
            room: room,
            transportProtocol: transportProtocol,
            ip: showsIPField ? ip.trimmed.nilWhenBlank : nil,
            updateInterval: showsUpdateIntervalField ? Int(updateInterval.trimmed) : nil,
            tuyaDeviceId: showsTuyaFields ? tuyaDeviceId.trimmed.nilWhenBlank : nil,
            tuyaDeviceLocalKey: showsTuyaFields ? tuyaDeviceLocalKey.trimmed.nilWhenBlank : nil,
            zigbeeFriendlyName: showsZigbeeFields ? zigbeeFriendlyName.trimmed.nilWhenBlank : nil
        )
    }
}
