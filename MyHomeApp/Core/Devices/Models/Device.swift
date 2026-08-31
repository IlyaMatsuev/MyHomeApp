import Foundation
import AnyCodable

struct Device: Codable, Identifiable, Hashable {
    let externalId: String
    let name: String

    let type: DeviceType
    let brand: DeviceBrand
    let room: DeviceRoom

    let transportProtocol: TransportProtocol
    // swiftlint:disable:next identifier_name
    let ip: String?
    let updateInterval: Int?

    let tuyaDeviceId: String?
    let tuyaDeviceLocalKey: String?

    let zigbeeFriendlyName: String?
    let zigbeeIeeeAddress: String?

    // TODO: Make controls "let"
    // "controls" and "measurements" might come undefined or empty
    // swiftlint:disable:next discouraged_optional_collection
    var controls: [String: AnyCodable]?
    // swiftlint:disable:next discouraged_optional_collection
    let measurements: [String: AnyCodable]?

    /// Only present on the devices listing, which the app requests with `includeConfig=true`.
    /// Mutation responses omit it, so it is carried forward — see `preservingConfig(from:)`.
    var config: DeviceConfig?

    var controlsUpdatedAt: Date?
    let measurementsUpdatedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    var id: String { externalId }
}

extension Device: Comparable {
    static func < (lhs: Device, rhs: Device) -> Bool {
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}

// MARK: - Config-driven layout

extension Device {
    /// Controls the device exposes, in the order the hub declares them.
    ///
    /// Falls back to the stored payload when the hub ships no config for this brand/type, so an
    /// unconfigured device still shows its state instead of an empty row.
    var controlItems: [DeviceConfigItem] {
        Self.items(declared: config?.controlItems, storedIn: controls)
    }

    var measurementItems: [DeviceConfigItem] {
        Self.items(declared: config?.measurementItems, storedIn: measurements)
    }

    /// Commands are stateless, so there is nothing stored to infer them from — no config, none.
    var commandItems: [DeviceConfigItem] {
        config?.commandItems ?? []
    }

    func controlValue(of item: DeviceConfigItem) -> AnyCodable? {
        controls?[item.name]
    }

    func measurementValue(of item: DeviceConfigItem) -> AnyCodable? {
        measurements?[item.name]
    }

    /// The hub returns `config` only on the devices listing, so an updated device inherits the
    /// config the app already knows rather than dropping every control from the screen.
    func preservingConfig(from previous: Device) -> Device {
        guard config == nil else { return self }
        var merged = self
        merged.config = previous.config
        return merged
    }

    private static func items(
        // swiftlint:disable:next discouraged_optional_collection
        declared: [DeviceConfigItem]?,
        // swiftlint:disable:next discouraged_optional_collection
        storedIn payload: [String: AnyCodable]?
    ) -> [DeviceConfigItem] {
        if let declared, !declared.isEmpty {
            return declared
        }
        guard let payload else { return [] }
        return payload
            .keys
            .sorted()
            .map { DeviceConfigItem.inferred(name: $0, value: payload[$0]) }
    }
}
