import Foundation
import AnyCodable
@testable import MyHomeApp

final class StubDeviceService: DeviceService, @unchecked Sendable {
    private(set) var fetchDevicesResult: Result<Page<Device>, Error> = .success(
        Page(items: [], page: 1, pageSize: 0, totalPages: 1, totalItems: 0)
    )
    var updateControlsResult: (String) -> Result<Device, Error> = { deviceId in
        .failure(MockDeviceService.DeviceNotFoundError(deviceId: deviceId))
    }
    var updateDeviceResult: (String) -> Result<Device, Error> = { deviceId in
        .failure(MockDeviceService.DeviceNotFoundError(deviceId: deviceId))
    }
    var sendCommandResult: (String) -> Result<Device, Error> = { deviceId in
        .failure(MockDeviceService.DeviceNotFoundError(deviceId: deviceId))
    }
    var deleteDeviceResult: Result<Void, Error> = .success(())

    private(set) var fetchDevicesCallCount = 0
    private(set) var updateControlsCalls: [(deviceId: String, controls: [String: AnyCodable])] = []
    private(set) var updateDeviceCalls: [(deviceId: String, payload: DeviceUpdatePayload)] = []
    private(set) var sendCommandCalls: [(deviceId: String, command: [String: AnyCodable])] = []
    private(set) var deleteDeviceCalls: [String] = []

    func fetchDevices() async throws -> Page<Device> {
        fetchDevicesCallCount += 1
        return try fetchDevicesResult.get()
    }

    func updateControls(deviceId: String, controls: [String: AnyCodable]) async throws -> Device {
        updateControlsCalls.append((deviceId, controls))
        return try updateControlsResult(deviceId).get()
    }

    func updateDevice(deviceId: String, payload: DeviceUpdatePayload) async throws -> Device {
        updateDeviceCalls.append((deviceId, payload))
        return try updateDeviceResult(deviceId).get()
    }

    func sendCommand(deviceId: String, command: [String: AnyCodable]) async throws -> Device {
        sendCommandCalls.append((deviceId, command))
        return try sendCommandResult(deviceId).get()
    }

    func deleteDevice(deviceId: String) async throws {
        deleteDeviceCalls.append(deviceId)
        try deleteDeviceResult.get()
    }

    func setDevices(_ devices: [Device]) {
        fetchDevicesResult = .success(
            Page(
                items: devices,
                page: 1,
                pageSize: devices.count,
                totalPages: 1,
                totalItems: devices.count
            )
        )
    }

    func setDevicesError(_ error: Error) {
        fetchDevicesResult = .failure(error)
    }

    /// Echoes back whatever device the call names, as the hub does for a successful mutation.
    func echo(_ device: Device) {
        updateControlsResult = { _ in .success(device) }
        updateDeviceResult = { _ in .success(device) }
        sendCommandResult = { _ in .success(device) }
    }
}
