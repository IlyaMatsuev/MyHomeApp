import AnyCodable

protocol DeviceService: Sendable {
    func fetchDevices() async throws -> Page<Device>
    func updateControls(deviceId: String, controls: [String: AnyCodable]) async throws -> Device
    func updateDevice(deviceId: String, payload: DeviceUpdatePayload) async throws -> Device
    func sendCommand(deviceId: String, command: [String: AnyCodable]) async throws -> Device
    func deleteDevice(deviceId: String) async throws
}
