
protocol DeviceService: Sendable {
    func fetchDevices() async throws -> Page<Device>
}
