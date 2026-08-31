import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

struct HubDeviceServiceTests {
    private let client: StubMyHomeAPIClient
    private let service: HubDeviceService

    init() {
        client = StubMyHomeAPIClient()
        service = HubDeviceService(client: client)
    }

    // MARK: - fetchDevices() — request shape

    @Test
    func fetchDevicesSendsGetDevicesAsProtectedRequest() async throws {
        client.response = .data(Self.encodeEmptyPage())

        _ = try await service.fetchDevices()

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .get)
        #expect(request.path == "/devices")
        #expect(request.protected == true)
        #expect(request.body == nil)
    }

    @Test
    func fetchDevicesAsksTheHubForDeviceConfigs() async throws {
        client.response = .data(Self.encodeEmptyPage())

        _ = try await service.fetchDevices()

        let request = try #require(client.sentRequests.first)
        #expect(request.query == ["pageSize": "20", "includeConfig": "true"])
    }

    // MARK: - fetchDevices() — success

    @Test
    func fetchDevicesReturnsDecodedPage() async throws {
        let lamp = Device.fixture(name: "Lamp")
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.tuyaLED)
            .build()
        let speaker = Device.fixture(name: "Speaker")
            .inRoom(.livingRoom)
            .build()
        let page = Page(
            items: [lamp, speaker],
            page: 1,
            pageSize: 20,
            totalPages: 1,
            totalItems: 2
        )
        client.response = .data(try Self.encode(page))

        let result = try await service.fetchDevices()

        #expect(result == page)
    }

    // MARK: - fetchDevices() — failure paths

    @Test
    func fetchDevicesPropagatesClientError() async {
        client.response = .error(HubAPIError.unauthorized)

        await #expect(throws: HubAPIError.unauthorized) {
            _ = try await service.fetchDevices()
        }
    }

    @Test
    func fetchDevicesPropagatesDecodingError() async {
        client.response = .data(Data("not-json".utf8))

        await #expect(throws: DecodingError.self) {
            _ = try await service.fetchDevices()
        }
    }

    // MARK: - updateControls() — request shape

    @Test
    func updateControlsSendsPutDeviceByIdAsProtectedRequest() async throws {
        client.response = .data(try Self.encode(Device.fixture(name: "Lamp").build()))

        _ = try await service.updateControls(deviceId: "device-42", controls: ["on": AnyCodable(true)])

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .put)
        #expect(request.path == "/devices/device-42")
        #expect(request.protected == true)
    }

    @Test
    func updateControlsNestsTheValuesUnderControls() async throws {
        client.response = .data(try Self.encode(Device.fixture(name: "Lamp").build()))

        _ = try await service.updateControls(
            deviceId: "device-42",
            controls: ["on": AnyCodable(false), "brightness": AnyCodable(40)]
        )

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode(ControlsPayload.self, from: body)
        #expect(decoded.controls == ["on": AnyCodable(false), "brightness": AnyCodable(40)])
    }

    @Test
    func updateControlsReturnsDecodedDevice() async throws {
        let device = Device.fixture(name: "Lamp").inRoom(.livingRoom).build()
        client.response = .data(try Self.encode(device))

        let result = try await service.updateControls(deviceId: device.externalId, controls: ["on": AnyCodable(true)])

        #expect(result == device)
    }

    @Test
    func updateControlsPropagatesClientError() async {
        client.response = .error(HubAPIError.unauthorized)

        await #expect(throws: HubAPIError.unauthorized) {
            _ = try await service.updateControls(deviceId: "device-42", controls: ["on": AnyCodable(true)])
        }
    }

    // MARK: - updateDevice()

    @Test
    func updateDeviceSendsPutDeviceByIdWithTheDetailsPayload() async throws {
        client.response = .data(try Self.encode(Device.fixture(name: "Lamp").build()))
        let payload = DeviceUpdatePayload(name: "Desk lamp", room: .office)

        _ = try await service.updateDevice(deviceId: "device-42", payload: payload)

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .put)
        #expect(request.path == "/devices/device-42")
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode(DetailsPayload.self, from: body)
        #expect(decoded.name == "Desk lamp")
        #expect(decoded.room == "office")
    }

    @Test
    func updateDeviceLeavesUnsetFieldsOutOfTheBody() async throws {
        client.response = .data(try Self.encode(Device.fixture(name: "Lamp").build()))

        _ = try await service.updateDevice(deviceId: "device-42", payload: DeviceUpdatePayload(name: "Desk lamp"))

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(Set(json.keys) == ["name"])
    }

    // MARK: - sendCommand()

    @Test
    func sendCommandPostsTheCommandToTheDeviceCommandEndpoint() async throws {
        let speaker = Device.fixture(name: "Speaker", type: .speaker, brand: .google).build()
        client.response = .data(try Self.encode(speaker))

        _ = try await service.sendCommand(deviceId: "device-42", command: ["text": AnyCodable("Dinner is ready")])

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .post)
        #expect(request.path == "/devices/device-42/command")
        #expect(request.protected == true)
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: body)
        #expect(decoded == ["text": AnyCodable("Dinner is ready")])
    }

    @Test
    func sendCommandPropagatesClientError() async {
        client.response = .error(HubAPIError.validation("text", "Text is required"))

        await #expect(throws: HubAPIError.validation("text", "Text is required")) {
            _ = try await service.sendCommand(deviceId: "device-42", command: ["text": AnyCodable("")])
        }
    }

    // MARK: - deleteDevice()

    @Test
    func deleteDeviceSendsDeleteDeviceById() async throws {
        try await service.deleteDevice(deviceId: "device-42")

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .delete)
        #expect(request.path == "/devices/device-42")
        #expect(request.protected == true)
        #expect(request.body == nil)
    }

    @Test
    func deleteDevicePropagatesClientError() async {
        client.response = .error(HubAPIError.notFound)

        await #expect(throws: HubAPIError.notFound) {
            try await service.deleteDevice(deviceId: "device-42")
        }
    }

    // MARK: - helpers

    private struct ControlsPayload: Decodable {
        let controls: [String: AnyCodable]
    }

    private struct DetailsPayload: Decodable {
        let name: String?
        let room: String?
    }

    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }

    private static func encodeEmptyPage() -> Data {
        // swiftlint:disable:next force_try
        try! encode(Page<Device>(items: [], page: 1, pageSize: 20, totalPages: 1, totalItems: 0))
    }
}
