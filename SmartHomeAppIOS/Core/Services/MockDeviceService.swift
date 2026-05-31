import Foundation
import AnyCodable

struct MockDeviceService: DeviceService {
    let operationDelay: Duration

    init(operationDelay: Duration = .seconds(1)) {
        self.operationDelay = operationDelay
    }

    func fetchDevices() async throws -> Page<Device> {
        let now = Date()
        try await Task.sleep(for: operationDelay)

        return Page(
            items: [
                Device(
                    externalId: "11111111-1111-1111-1111-111111111111",
                    name: "Office Table LED",
                    type: .led,
                    brand: .philips,
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
                        "color": "#B7D4FF",
                    ],
                    measurements: [:],
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
                    measurements: [:],
                    controlsUpdatedAt: now,
                    measurementsUpdatedAt: nil,
                    createdAt: now,
                    updatedAt: now,
                ),
                Device(
                    externalId: "11111111-1111-1111-4444-111111111111",
                    name: "Main ceiling light",
                    type: .switch,
                    brand: .shelly,
                    room: .livingRoom,
                    transportProtocol: .http,
                    ip: "192.168.0.104",
                    updateInterval: nil,
                    tuyaDeviceId: nil,
                    tuyaDeviceLocalKey: nil,
                    zigbeeFriendlyName: nil,
                    zigbeeIeeeAddress: nil,
                    controls: ["on": false],
                    measurements: [:],
                    controlsUpdatedAt: now,
                    measurementsUpdatedAt: nil,
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
                        "linkquality": 204,
                    ],
                    controlsUpdatedAt: nil,
                    measurementsUpdatedAt: now,
                    createdAt: now,
                    updatedAt: now,
                )
            ],
            page: 1,
            pageSize: 10,
            totalPages: 1,
            totalItems: 5
        )
    }
}
