import Observation

@Observable
@MainActor
final class DevicesRouter {
    enum Destination: Identifiable, Hashable {
        case edit(deviceId: String)

        var id: String {
            switch self {
            case .edit(let deviceId): "edit-\(deviceId)"
            }
        }
    }

    var destination: Destination?

    func editDevice(_ device: Device) {
        destination = .edit(deviceId: device.id)
    }

    func dismiss() {
        destination = nil
    }
}
