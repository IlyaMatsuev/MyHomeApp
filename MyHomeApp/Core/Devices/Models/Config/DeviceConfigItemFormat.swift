/// Extra shape a string command/control value has to match.
///
/// Mirrors `DeviceConfigItemFormat` in the hub. Unknown formats decode into `unsupported` and are
/// not enforced client-side — the hub still rejects a bad value.
enum DeviceConfigItemFormat: Hashable {
    case hexColor
    case ipAddress
    case url
    case unsupported(String)
}

extension DeviceConfigItemFormat {
    init(wireValue: String) {
        switch wireValue {
        case "hex-color": self = .hexColor
        case "ip": self = .ipAddress
        case "url": self = .url
        default: self = .unsupported(wireValue)
        }
    }

    var wireValue: String {
        switch self {
        case .hexColor: return "hex-color"
        case .ipAddress: return "ip"
        case .url: return "url"
        case .unsupported(let value): return value
        }
    }

    var label: String {
        switch self {
        case .hexColor: return "hex-color"
        case .ipAddress: return "IP address"
        case .url: return "URL"
        case .unsupported(let value): return value
        }
    }
}

extension DeviceConfigItemFormat: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(wireValue: try container.decode(String.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wireValue)
    }
}
