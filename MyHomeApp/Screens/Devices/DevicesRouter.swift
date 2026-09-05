import Observation

@Observable
@MainActor
final class DevicesRouter {
    enum Destination: Identifiable, Hashable {
        case deviceDetails(deviceId: String)

        var id: String {
            switch self {
            case .deviceDetails(let deviceId): "deviceDetails-\(deviceId)"
            }
        }
    }

    var destination: Destination?

    func openDetails(_ device: Device) {
        destination = .deviceDetails(deviceId: device.id)
    }

    func dismiss() {
        destination = nil
    }
}
