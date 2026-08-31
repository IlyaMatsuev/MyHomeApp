import Foundation
import AnyCodable

struct MockDeviceService: DeviceService {
    let operationDelay: Duration

    static var allDevices: [Device] {
        let now = Date()
        return [
            Device(
                externalId: "11111111-1111-1111-1111-111111111111",
                name: "Office Table LED",
                type: .led,
                brand: .tuya,
                room: .office,
                transportProtocol: .tuya,
                ip: "192.168.0.101",
                updateInterval: nil,
                tuyaDeviceId: "qiwdiqnw",
                tuyaDeviceLocalKey: "qiwhqiwd",
                zigbeeFriendlyName: nil,
                zigbeeIeeeAddress: nil,
                controls: [
                    "on": false,
                    "brightness": 100,
                    "color": "#B7D4FF"
                ],
                measurements: [:],
                config: MockDeviceConfigs.tuyaLED,
                controlsUpdatedAt: now,
                measurementsUpdatedAt: nil,
                createdAt: now,
                updatedAt: now,
            ),
            Device(
                externalId: "11111111-1111-1111-2222-111111111111",
                name: "Google Nest",
                type: .speaker,
                brand: .google,
                room: .livingRoom,
                transportProtocol: .http,
                ip: "192.168.0.102",
                updateInterval: nil,
                tuyaDeviceId: nil,
                tuyaDeviceLocalKey: nil,
                zigbeeFriendlyName: nil,
                zigbeeIeeeAddress: nil,
                controls: [:],
                measurements: [:],
                config: MockDeviceConfigs.googleSpeaker,
                controlsUpdatedAt: nil,
                measurementsUpdatedAt: nil,
                createdAt: now,
                updatedAt: now,
            ),
            Device(
                externalId: "11111111-1111-1111-3333-111111111111",
                name: "Warm light",
                type: .plug,
                brand: .shelly,
                room: .livingRoom,
                transportProtocol: .http,
                ip: "192.168.0.103",
                updateInterval: nil,
                tuyaDeviceId: nil,
                tuyaDeviceLocalKey: nil,
                zigbeeFriendlyName: nil,
                zigbeeIeeeAddress: nil,
                controls: ["on": false],
                measurements: [
                    "voltage": 231.4,
                    "current": 0.12,
                    "power": 27.5
                ],
                config: MockDeviceConfigs.shellyPlug,
                controlsUpdatedAt: now,
                measurementsUpdatedAt: now,
                createdAt: now,
                updatedAt: now,
            ),
            Device(
                externalId: "11111111-1111-1111-4444-111111111111",
                name: "Main ceiling light",
                type: .led,
                brand: .shelly,
                room: .livingRoom,
                transportProtocol: .http,
                ip: "192.168.0.104",
                updateInterval: nil,
                tuyaDeviceId: nil,
                tuyaDeviceLocalKey: nil,
                zigbeeFriendlyName: nil,
                zigbeeIeeeAddress: nil,
                controls: [
                    "on": true,
                    "mode": "cct",
                    "brightness": 60,
                    "color": "#FFD9A0",
                    "temperature": 3200,
                    "transitionDuration": 1.5
                ],
                measurements: ["power": 8.4],
                config: MockDeviceConfigs.shellyLED,
                controlsUpdatedAt: now,
                measurementsUpdatedAt: now,
                createdAt: now,
                updatedAt: now,
            ),
            Device(
                externalId: "11111111-1111-1111-5555-111111111111",
                name: "Main light remote",
                type: .remote,
                brand: .philips,
                room: .general,
                transportProtocol: .zigbee,
                ip: nil,
                updateInterval: nil,
                tuyaDeviceId: nil,
                tuyaDeviceLocalKey: nil,
                zigbeeFriendlyName: "MainLightRemote",
                zigbeeIeeeAddress: "0x0017837481F7Dcad",
                controls: [:],
                measurements: [
                    "battery": 100,
                    "linkquality": 204
                ],
                config: MockDeviceConfigs.philipsRemote,
                controlsUpdatedAt: nil,
                measurementsUpdatedAt: now,
                createdAt: now,
                updatedAt: now,
            )
        ]
    }

    init(operationDelay: Duration = .seconds(1)) {
        self.operationDelay = operationDelay
    }

    func fetchDevices() async throws -> Page<Device> {
        try await Task.sleep(for: operationDelay)
        return Page(
            items: Self.allDevices,
            page: 1,
            pageSize: 10,
            totalPages: 1,
            totalItems: 5
        )
    }

    func updateControls(deviceId: String, controls: [String: AnyCodable]) async throws -> Device {
        var device = try Self.device(withId: deviceId)
        try await Task.sleep(for: operationDelay)

        device.controls = (device.controls ?? [:]).merging(controls) { _, new in new }
        device.controlsUpdatedAt = Date()
        return device
    }

    func updateDevice(deviceId: String, payload: DeviceUpdatePayload) async throws -> Device {
        let device = try Self.device(withId: deviceId)
        try await Task.sleep(for: operationDelay)
        return Self.applying(payload, to: device)
    }

    func sendCommand(deviceId: String, command: [String: AnyCodable]) async throws -> Device {
        let device = try Self.device(withId: deviceId)
        try await Task.sleep(for: operationDelay)
        return device
    }

    func deleteDevice(deviceId: String) async throws {
        _ = try Self.device(withId: deviceId)
        try await Task.sleep(for: operationDelay)
    }

    private static func device(withId deviceId: String) throws -> Device {
        guard let device = allDevices.first(where: { $0.externalId == deviceId }) else {
            throw DeviceNotFoundError(deviceId: deviceId)
        }
        return device
    }

    private static func applying(_ payload: DeviceUpdatePayload, to device: Device) -> Device {
        Device(
            externalId: device.externalId,
            name: payload.name ?? device.name,
            type: payload.type ?? device.type,
            brand: payload.brand ?? device.brand,
            room: payload.room ?? device.room,
            transportProtocol: payload.transportProtocol ?? device.transportProtocol,
            ip: payload.ip ?? device.ip,
            updateInterval: payload.updateInterval ?? device.updateInterval,
            tuyaDeviceId: payload.tuyaDeviceId ?? device.tuyaDeviceId,
            tuyaDeviceLocalKey: payload.tuyaDeviceLocalKey ?? device.tuyaDeviceLocalKey,
            zigbeeFriendlyName: payload.zigbeeFriendlyName ?? device.zigbeeFriendlyName,
            zigbeeIeeeAddress: device.zigbeeIeeeAddress,
            controls: device.controls,
            measurements: device.measurements,
            config: device.config,
            controlsUpdatedAt: device.controlsUpdatedAt,
            measurementsUpdatedAt: device.measurementsUpdatedAt,
            createdAt: device.createdAt,
            updatedAt: Date()
        )
    }

    struct DeviceNotFoundError: LocalizedError {
        let deviceId: String

        var errorDescription: String? {
            "Device with id \"\(deviceId)\" was not found"
        }

        init(deviceId: String) {
            self.deviceId = deviceId
        }
    }
}
