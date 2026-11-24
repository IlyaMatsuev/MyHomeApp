/// A free-text field in the device details form whose value the hub bounds.
enum DeviceField: Hashable, CaseIterable {
    case name
    case ip
    case updateInterval
    case tuyaDeviceId
    case tuyaDeviceLocalKey
    case zigbeeFriendlyName
}
