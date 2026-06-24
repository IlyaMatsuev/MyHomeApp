import Foundation
import Observation
import AnyCodable
import os

struct DeviceRoomGroup: Identifiable, Hashable {
    let room: DeviceRoom
    let devices: [Device]

    var id: String { room.rawValue }
    var title: String { room.label }
}

@Observable
@MainActor
final class DevicesViewModel {
    private static let logger = Logger(subsystem: "SmartHomeApp", category: "DevicesViewModel")

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var selectedRoom: DeviceRoomFilter

    private(set) var state: LoadState = .idle
    // TODO: Maybe just store them as Dictionary with rooms as keys?
    private(set) var roomGroups: [DeviceRoomGroup] = []

    private(set) var loadingDeviceIds: Set<String> = []

    private let service: DeviceService
    private let toastStore: ToastStore

    var availableRooms: [DeviceRoom] { roomGroups.map(\.room) }

    var visibleRoomGroups: [DeviceRoomGroup] {
        switch selectedRoom {
        case .all:
            roomGroups

        case .specific(let room):
            roomGroups.filter { $0.room == room }
        }
    }

    init(service: DeviceService, toastStore: ToastStore, selectedRoom: DeviceRoomFilter = .all) {
        self.service = service
        self.toastStore = toastStore
        self.selectedRoom = selectedRoom
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
            toastStore.error(errorMessage(for: error))
        }
    }

    func isLoading(_ device: Device) -> Bool {
        loadingDeviceIds.contains(device.id)
    }

    func toggle(_ device: Device, key: String, to newValue: Bool) {
        Task { await apply(.toggle(key: key, value: newValue), to: device) }
    }

    private func apply(_ change: DeviceControlType, to device: Device) async {
        let previous = device

        loadingDeviceIds.insert(device.id)
        applyLocally(change, to: device)

        do {
            let updated = try await service.updateControl(deviceId: device.id, controlType: change)
            replaceDevice(updated)
        } catch {
            replaceDevice(previous)
            toastStore.error(errorMessage(for: error))
            Self.logger.error("Error while updating a control for \"\(device.id)\": \(error.localizedDescription)")
        }

        loadingDeviceIds.remove(device.id)
    }

    private func applyLocally(_ change: DeviceControlType, to device: Device) {
        var updated = device
        var controls = updated.controls ?? [:]
        switch change {
        case .toggle(let key, let value):
            controls[key] = AnyCodable(value)
        }
        updated.controls = controls
        replaceDevice(updated)
    }

    private func replaceDevice(_ device: Device) {
        roomGroups = roomGroups.map { group in
            guard let index = group.devices.firstIndex(where: { $0.id == device.id }) else {
                return group
            }
            var devices = group.devices
            devices[index] = device
            return DeviceRoomGroup(room: group.room, devices: devices.sorted())
        }
    }

    private static func group(_ devices: [Device]) -> [DeviceRoomGroup] {
        let grouped = Dictionary(grouping: devices, by: { $0.room })
        return grouped
            .map { DeviceRoomGroup(room: $0, devices: $1.sorted()) }
            .sorted(using: KeyPathComparator(\.room))
    }

    private func errorMessage(for error: Error) -> String {
        switch error {
        case HubAPIError.transport:
            return "No Internet connection"
        case HubAPIError.unauthorized, HubAPIError.forbidden:
            return "Your session has expired, please log in again"
        case HubAPIError.notFound:
            return "This device does not exist anymore. Try refreshing the page"
        case HubAPIError.validation:
            return "Failed updating the device"
        default:
            return "Oops... Something went wrong"
        }
    }
}
