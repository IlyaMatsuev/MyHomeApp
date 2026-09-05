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
    private static let logger = Logger(subsystem: "MyHomeApp", category: "DevicesViewModel")

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

    /// The value each staged control had before the user touched it, so a failed update can be
    /// rolled back even after the slider has been dragged well past where the request started.
    private var rollbackValues: [ControlKey: AnyCodable?] = [:]

    private struct ControlKey: Hashable {
        let deviceId: String
        let name: String
    }

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

    // MARK: - Loading

    func load() async {
        state = .loading
        do {
            try await fetchDevices()
        } catch {
            state = .failed(DeviceError.text(for: error))
        }
    }

    func refresh() async {
        do {
            try await fetchDevices()
        } catch {
            toastStore.error(DeviceError.text(for: error))
        }
    }

    func isLoading(_ device: Device) -> Bool {
        loadingDeviceIds.contains(device.id)
    }

    func device(withId deviceId: String) -> Device? {
        roomGroups.lazy.compactMap { $0.devices.first { $0.id == deviceId } }.first
    }

    /// Writes a control locally without contacting the hub, so a slider stays smooth while dragging.
    func stageControl(_ deviceId: String, name: String, value: AnyCodable) {
        guard let device = device(withId: deviceId) else { return }

        let key = ControlKey(deviceId: deviceId, name: name)
        if rollbackValues[key] == nil {
            rollbackValues[key] = device.controls?[name]
        }

        writeControl(name, of: device, to: value)
    }

    /// Sends the staged value of a control and reconciles the row with the hub's answer.
    func commitControl(_ deviceId: String, name: String) async {
        guard let device = device(withId: deviceId), let staged = device.controls?[name] else { return }
        let rollback = rollbackValues.removeValue(forKey: ControlKey(deviceId: deviceId, name: name))

        loadingDeviceIds.insert(deviceId)
        defer { loadingDeviceIds.remove(deviceId) }

        do {
            let updated = try await service.updateControls(deviceId: deviceId, controls: [name: staged])
            replaceDevice(updated.preservingConfig(from: device))
        } catch {
            if let rollback, let current = self.device(withId: deviceId) {
                writeControl(name, of: current, to: rollback)
            }
            toastStore.error(DeviceError.text(for: error))
            Self.logger.error("Failed to update control \"\(name)\" of \"\(deviceId)\": \(error.localizedDescription)")
        }
    }

    func setControl(_ deviceId: String, name: String, to value: AnyCodable) {
        stageControl(deviceId, name: name, value: value)
        Task { await commitControl(deviceId, name: name) }
    }

    func sendCommand(_ deviceId: String, name: String, value: AnyCodable, label: String) async {
        loadingDeviceIds.insert(deviceId)
        defer { loadingDeviceIds.remove(deviceId) }

        do {
            _ = try await service.sendCommand(deviceId: deviceId, command: [name: value])
            toastStore.success("\(label) sent")
        } catch {
            toastStore.error(DeviceError.text(for: error))
            Self.logger.error("Failed to send command \"\(name)\" to \"\(deviceId)\": \(error.localizedDescription)")
        }
    }

    func replaceDevice(_ device: Device) {
        roomGroups = Self.group(
            roomGroups
                .flatMap(\.devices)
                .map { $0.id == device.id ? device : $0 }
        )
    }

    func removeDevice(withId deviceId: String) {
        roomGroups = Self.group(roomGroups.flatMap(\.devices).filter { $0.id != deviceId })
        rollbackValues = rollbackValues.filter { $0.key.deviceId != deviceId }
    }

    private static func group(_ devices: [Device]) -> [DeviceRoomGroup] {
        let grouped = Dictionary(grouping: devices, by: { $0.room })
        return grouped
            .map { DeviceRoomGroup(room: $0, devices: $1.sorted()) }
            .sorted(using: KeyPathComparator(\.room))
    }

    private func fetchDevices() async throws {
        // TODO: Need to query all devices, or implement lazy loading or something
        let devicesPage = try await service.fetchDevices()
        roomGroups = Self.group(devicesPage.items)
        rollbackValues = [:]
        state = .loaded
    }

    private func writeControl(_ name: String, of device: Device, to value: AnyCodable?) {
        var updated = device
        var controls = updated.controls ?? [:]
        if let value {
            controls[name] = value
        } else {
            controls.removeValue(forKey: name)
        }
        updated.controls = controls
        replaceDevice(updated)
    }
}
