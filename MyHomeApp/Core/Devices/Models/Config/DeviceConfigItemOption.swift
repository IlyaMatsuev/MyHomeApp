/// One choice of an `enum` command/control, with the hub-side name the app sends back.
///
/// Mirrors `DeviceConfigItemValue` in the hub. `path` is the device-side mapping and is the hub's
/// business — the app always sends `name`.
struct DeviceConfigItemOption: Codable, Hashable, Identifiable {
    let label: String
    let name: String
    let path: String?

    var id: String { name }
}
