import Foundation
import AnyCodable

struct HubDeviceService: DeviceService {
    private struct UpdateControlsRequest: Encodable {
        let controls: [String: AnyCodable]
    }

    private let client: MyHomeAPIClient

    init(client: MyHomeAPIClient) {
        self.client = client
    }

    // TODO: Handle errors (401, 500)
    func fetchDevices() async throws -> [Device] {
        let request = HubRequest.get("/devices", ["all": "true", "includeConfig": "true"])
        let page: Page<Device> = try await client.send(request)
        return page.items
    }

    // TODO: Handle errors: 400, 401, 404, 500
    func updateControls(deviceId: String, controls: [String: AnyCodable]) async throws -> Device {
        let request = try HubRequest.put("/devices/\(deviceId)", UpdateControlsRequest(controls: controls))
        return try await client.send(request)
    }

    func updateDevice(deviceId: String, payload: DeviceUpdatePayload) async throws -> Device {
        let request = try HubRequest.put("/devices/\(deviceId)", payload)
        return try await client.send(request)
    }

    /// Commands are stateless — the hub passes them through to the device and echoes the device back.
    func sendCommand(deviceId: String, command: [String: AnyCodable]) async throws -> Device {
        let request = try HubRequest.post("/devices/\(deviceId)/command", command)
        return try await client.send(request)
    }

    func deleteDevice(deviceId: String) async throws {
        let request = HubRequest.delete("/devices/\(deviceId)")
        try await client.send(request)
    }
}
