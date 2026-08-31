/// Metadata describing what a device can do, keyed on the hub by brand/type/transport protocol.
///
/// Mirrors `DeviceConfigs.DeviceConfigResponse` in the hub. It only rides along on responses
/// requested with `includeConfig=true`, so mutation responses come back without it —
/// see `Device.preservingConfig(from:)`.
struct DeviceConfig: Codable, Hashable {
    // swiftlint:disable discouraged_optional_collection
    let commands: [DeviceConfigItem]?
    let controls: [DeviceConfigItem]?
    let measurements: [DeviceConfigItem]?
    // swiftlint:enable discouraged_optional_collection
}

extension DeviceConfig {
    var commandItems: [DeviceConfigItem] { commands ?? [] }
    var controlItems: [DeviceConfigItem] { controls ?? [] }
    var measurementItems: [DeviceConfigItem] { measurements ?? [] }
}
