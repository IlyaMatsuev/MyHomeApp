/// Value type of a single command/control/measurement, as declared by the hub's device config.
///
/// Mirrors `DeviceConfigItemType` in the hub (`src/device-configs/interfaces`). The hub can ship a
/// new type before the app knows about it, so an unrecognised one decodes into `unsupported`
/// instead of failing the whole devices page.
enum DeviceConfigItemType: Hashable {
    case boolean
    case number
    case string
    case enumeration
    case object
    case unsupported(String)
}

extension DeviceConfigItemType {
    init(wireValue: String) {
        switch wireValue {
        case "boolean": self = .boolean
        case "number": self = .number
        case "string": self = .string
        case "enum": self = .enumeration
        case "object": self = .object
        default: self = .unsupported(wireValue)
        }
    }

    var wireValue: String {
        switch self {
        case .boolean: return "boolean"
        case .number: return "number"
        case .string: return "string"
        case .enumeration: return "enum"
        case .object: return "object"
        case .unsupported(let value): return value
        }
    }

    /// `false` for shapes the app has no editor for — they are shown read-only.
    var isEditable: Bool {
        switch self {
        case .boolean, .number, .string, .enumeration: return true
        case .object, .unsupported: return false
        }
    }
}

extension DeviceConfigItemType: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(wireValue: try container.decode(String.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wireValue)
    }
}
