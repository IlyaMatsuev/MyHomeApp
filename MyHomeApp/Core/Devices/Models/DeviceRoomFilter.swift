enum DeviceRoomFilter: Hashable {
    case all
    case specific(DeviceRoom)
}

extension DeviceRoomFilter {
    var label: String {
        switch self {
        case .all: return "All"
        case .specific(let room): return room.label
        }
    }
}
