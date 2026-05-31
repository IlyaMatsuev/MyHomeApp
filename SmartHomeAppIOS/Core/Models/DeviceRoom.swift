
enum DeviceRoom: String, Codable, Hashable, CaseIterable {
    case general = "none"
    case livingRoom = "living-room"
    case bedroom
    case bathroom
    case kitchen
    case office

    var label: String {
        switch self {
        case .general: return ("General")
        case .livingRoom: return ("Living Room")
        case .bedroom: return ("Bedroom")
        case .bathroom: return ("Bathroom")
        case .kitchen: return ("Kitchen")
        case .office: return ("Office")
        }
    }
}

extension DeviceRoom: Comparable {
    static func < (lhs: DeviceRoom, rhs: DeviceRoom) -> Bool {
        // "General" (no room) is at the top
        if lhs == .general {
            return true
        }
        if rhs == .general {
            return false
        }
        return lhs.label < rhs.label
    }
}
