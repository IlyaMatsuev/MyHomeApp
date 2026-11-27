import Foundation
import AnyCodable
import os
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
    func fetchDevicesAsksForTheFirstFullPageWithDeviceConfigs() async throws {
        client.response = .data(Self.encodeEmptyPage())

        _ = try await service.fetchDevices()

        let request = try #require(client.sentRequests.first)
        #expect(request.query == ["page": "1", "pageSize": "50", "includeConfig": "true"])
    }

    // MARK: - fetchDevices() — success

    @Test
    func fetchDevicesReturnsTheDevicesOfASinglePage() async throws {
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
            pageSize: 50,
            totalPages: 1,
            totalItems: 2
        )
        client.response = .data(try Self.encode(page))

        let result = try await service.fetchDevices()

        #expect(result == [lamp, speaker])
        #expect(client.sentRequests.count == 1)
    }

    @Test
    func fetchDevicesSendsOneRequestWhenTheHubHasNoDevices() async throws {
        // The hub reports `totalPages == 0` for an empty collection, not 1.
        let page = Page<Device>(items: [], page: 1, pageSize: 50, totalPages: 0, totalItems: 0)
        client.response = .data(try Self.encode(page))

        let result = try await service.fetchDevices()

        #expect(result.isEmpty)
        #expect(client.sentRequests.count == 1)
    }

    // MARK: - fetchDevices() — pagination

    @Test
    @MainActor
    func fetchDevicesFollowsEveryPageTheHubReports() async throws {
        let devices = (1...53).map { Device.fixture(name: "Device \($0)").build() }
        let firstPage = Page(items: Array(devices.prefix(50)), page: 1, pageSize: 50, totalPages: 2, totalItems: 53)
        let secondPage = Page(items: Array(devices.dropFirst(50)), page: 2, pageSize: 50, totalPages: 2, totalItems: 53)
        let requests = OSAllocatedUnfairLock<[URLRequest]>(initialState: [])
        let hubClient = Self.makeHubClient(host: "paged.hub.local") { request in
            requests.withLock { $0.append(request) }
            let page = Self.query(of: request)["page"] == "2" ? secondPage : firstPage
            return try Self.hubResponse(for: request, body: Self.encodeForHub(page))
        }

        let result = try await HubDeviceService(client: hubClient).fetchDevices()

        #expect(result == devices)
        let queries = requests.withLock { $0 }.map(Self.query(of:))
        #expect(queries == [
            ["page": "1", "pageSize": "50", "includeConfig": "true"],
            ["page": "2", "pageSize": "50", "includeConfig": "true"]
        ])
    }

    @Test
    @MainActor
    func fetchDevicesFailsWhenALaterPageFails() async {
        let firstPage = Page(items: [Device.fixture(name: "Lamp").build()], page: 1, pageSize: 50, totalPages: 2, totalItems: 51)
        let hubClient = Self.makeHubClient(host: "failing-page.hub.local") { request in
            guard Self.query(of: request)["page"] == "1" else {
                return try Self.hubResponse(for: request, status: 500)
            }
            return try Self.hubResponse(for: request, body: Self.encodeForHub(firstPage))
        }

        await #expect(throws: HubAPIError.unexpected) {
            _ = try await HubDeviceService(client: hubClient).fetchDevices()
        }
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
        try! encode(Page<Device>(items: [], page: 1, pageSize: 50, totalPages: 1, totalItems: 0))
    }

    /// A real `HubAPIClient` over `TestURLProtocol`, answering only `host` so it can't race other suites.
    @MainActor
    private static func makeHubClient(host: String, handler: @escaping TestURLProtocol.Handler) -> HubAPIClient {
        let context = HubAPIContext()
        context.attach(
            auth: StubAuthProvider(sessionToken: AuthToken.fixture()),
            servers: StubServerProvider(selectedServer: Server(.http, "\(host):8080"))
        )
        return HubAPIClient(context: context, session: .testSession(host: host, handler: handler))
    }

    private static func hubResponse(
        for request: URLRequest,
        status: Int = 200,
        body: Data = Data()
    ) throws -> (HTTPURLResponse, Data) {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil) else {
            throw URLError(.badURL)
        }
        return (response, body)
    }

    private static func query(of request: URLRequest) -> [String: String] {
        guard let url = request.url,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    /// `JSONDecoder.hubAPI` only accepts ISO-8601 dates with fractional seconds, the way the hub sends them.
    private static func encodeForHub<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, dateEncoder in
            var container = dateEncoder.singleValueContainer()
            try container.encode(date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
        }
        return try encoder.encode(value)
    }
}
