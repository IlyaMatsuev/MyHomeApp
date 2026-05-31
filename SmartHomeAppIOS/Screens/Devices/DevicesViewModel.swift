import Foundation
import Observation

struct DeviceRoomGroup: Identifiable, Hashable {
    let room: DeviceRoom
    let devices: [Device]

    var id: String { room.rawValue }
    var title: String { room.label }
}

@Observable
@MainActor
final class DevicesViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: LoadState = .idle
    private(set) var roomGroups: [DeviceRoomGroup] = []

    private let service: DeviceService

    init(service: DeviceService) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            // TODO: Need to query all devices, or implement lazy loading or something
            let devicesPage = try await service.fetchDevices()
            roomGroups = Self.group(devicesPage.items)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private static func group(_ devices: [Device]) -> [DeviceRoomGroup] {
        let grouped = Dictionary(grouping: devices, by: { $0.room })
        return grouped
            .map { DeviceRoomGroup(room: $0, devices: $1.sorted()) }
            .sorted(using: KeyPathComparator(\.room))
    }
}
