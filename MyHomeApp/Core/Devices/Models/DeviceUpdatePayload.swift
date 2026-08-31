/// Body of `PUT /devices/:externalId`, carrying only the details fields the user edited.
///
/// Mirrors `Devices.DeviceUpdate` in the hub. Controls and commands travel on their own requests,
/// so they are deliberately not part of this payload.
struct DeviceUpdatePayload: Encodable, Equatable {
    var name: String?
    var type: DeviceType?
    var brand: DeviceBrand?
    var room: DeviceRoom?
    var transportProtocol: TransportProtocol?
    // swiftlint:disable:next identifier_name
    var ip: String?
    var updateInterval: Int?
    var tuyaDeviceId: String?
    var tuyaDeviceLocalKey: String?
    var zigbeeFriendlyName: String?
}
