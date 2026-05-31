
enum DeviceBrand: String, Codable, Hashable, CaseIterable {
    case google
    case shelly
    case tuya
    case philips
    case esp32
}

extension DeviceBrand {
    var label: String {
        switch self {
        case .google: return ("Google")
        case .shelly: return ("Shelly")
        case .tuya: return ("Tuya")
        case .philips: return ("Philips")
        case .esp32: return ("ESP32")
        }
    }
}
