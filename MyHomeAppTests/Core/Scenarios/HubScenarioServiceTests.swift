import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

struct HubScenarioServiceTests {
    private let client: StubMyHomeAPIClient
    private let service: HubScenarioService

    init() {
        client = StubMyHomeAPIClient()
        service = HubScenarioService(client: client)
    }

    // MARK: - fetchScenarios()

    @Test
    func fetchScenariosSendsGetScenariosAsProtectedRequest() async throws {
        client.response = .data(try Self.encode(Self.emptyPage))

        _ = try await service.fetchScenarios()

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .get)
        #expect(request.path == "/scenarios")
        #expect(request.protected == true)
        #expect(request.body == nil)
    }

    @Test
    func fetchScenariosAsksTheHubForAllScenariosIncludingInactive() async throws {
        client.response = .data(try Self.encode(Self.emptyPage))

        _ = try await service.fetchScenarios()

        let request = try #require(client.sentRequests.first)
        #expect(
            request.query == ["all": "true", "includeInactive": "true"],
            "The hub pages its list and filters inactive scenarios out unless asked otherwise"
        )
    }

    @Test
    func fetchScenariosReturnsThePageItems() async throws {
        let warmLight = Scenario.fixture(name: "Warm light on").build()
        let nightOff = Scenario.fixture(name: "Everything off at night", active: false).build()
        let page = Page(items: [warmLight, nightOff], page: 1, pageSize: 2, totalPages: 1, totalItems: 2)
        client.response = .data(try Self.encode(page))

        let result = try await service.fetchScenarios()

        #expect(result == [warmLight, nightOff])
    }

    @Test
    func fetchScenariosReturnsTwoPagesWorthOfScenariosFromOneRequest() async throws {
        // One past the hub's MAX_PAGE_SIZE of 50, so any paged request would need a second page.
        let scenarios = (1...51).map { Scenario.fixture(name: "Scenario \($0)").build() }
        let page = Page(items: scenarios, page: 1, pageSize: 51, totalPages: 1, totalItems: 51)
        client.response = .data(try Self.encode(page))

        let result = try await service.fetchScenarios()

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.query["all"] == "true", "Without all=true the hub caps the response at one page")
        #expect(result == scenarios)
    }

    @Test
    func fetchScenariosPropagatesClientError() async {
        client.response = .error(HubAPIError.unauthorized)

        await #expect(throws: HubAPIError.unauthorized) {
            _ = try await service.fetchScenarios()
        }
    }

    @Test
    func fetchScenariosPropagatesDecodingError() async {
        client.response = .data(Data("not-json".utf8))

        await #expect(throws: DecodingError.self) {
            _ = try await service.fetchScenarios()
        }
    }

    // MARK: - createScenario()

    @Test
    func createScenarioPostsToScenarios() async throws {
        let scenario = Scenario.fixture(name: "Warm light on").build()
        client.response = .data(try Self.encode(scenario))

        _ = try await service.createScenario(payload: Self.payload)

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .post)
        #expect(request.path == "/scenarios")
        #expect(request.protected == true)
    }

    @Test
    func createScenarioSerializesTheWritableFieldsOnly() async throws {
        let scenario = Scenario.fixture(name: "Warm light on").build()
        client.response = .data(try Self.encode(scenario))

        _ = try await service.createScenario(payload: Self.payload)

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let object = try JSONSerialization.jsonObject(with: body)
        let json = try #require(object as? [String: Any])

        #expect(json["name"] as? String == "Warm light on")
        #expect(json["active"] as? Bool == true)
        #expect(json["group"] as? String == "living_room")
        #expect(json["actions"] != nil)
        #expect(json["externalId"] == nil)
        #expect(json["createdAt"] == nil)
    }

    @Test
    func createScenarioReturnsTheDecodedScenario() async throws {
        let scenario = Scenario.fixture(name: "Warm light on").inGroup("living_room").build()
        client.response = .data(try Self.encode(scenario))

        let result = try await service.createScenario(payload: Self.payload)

        #expect(result == scenario)
    }

    @Test
    func createScenarioPropagatesClientError() async {
        client.response = .error(HubAPIError.validation("name", "Name is required"))

        await #expect(throws: HubAPIError.validation("name", "Name is required")) {
            _ = try await service.createScenario(payload: Self.payload)
        }
    }

    // MARK: - updateScenario()

    @Test
    func updateScenarioPutsToScenarioById() async throws {
        let scenario = Scenario.fixture(name: "Warm light on").build()
        client.response = .data(try Self.encode(scenario))

        _ = try await service.updateScenario(scenarioId: "scenario-42", payload: Self.payload)

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .put)
        #expect(request.path == "/scenarios/scenario-42")
        #expect(request.protected == true)
        #expect(request.body != nil)
    }

    @Test
    func updateScenarioPropagatesClientError() async {
        client.response = .error(HubAPIError.notFound)

        await #expect(throws: HubAPIError.notFound) {
            _ = try await service.updateScenario(scenarioId: "scenario-42", payload: Self.payload)
        }
    }

    // MARK: - setActive()

    @Test
    func setActiveSendsAPartialPutWithOnlyTheActiveFlag() async throws {
        let scenario = Scenario.fixture(name: "Warm light on").build()
        client.response = .data(try Self.encode(scenario))

        _ = try await service.setActive(scenarioId: "scenario-42", active: false)

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .put)
        #expect(request.path == "/scenarios/scenario-42")

        let body = try #require(request.body)
        let object = try JSONSerialization.jsonObject(with: body)
        let json = try #require(object as? [String: Any])
        #expect(json["active"] as? Bool == false)
        #expect(json.count == 1, "Toggling must not resend the whole scenario")
    }

    @Test
    func setActivePropagatesClientError() async {
        client.response = .error(HubAPIError.notFound)

        await #expect(throws: HubAPIError.notFound) {
            _ = try await service.setActive(scenarioId: "scenario-42", active: true)
        }
    }

    // MARK: - deleteScenario()

    @Test
    func deleteScenarioSendsDeleteScenarioById() async throws {
        try await service.deleteScenario(scenarioId: "scenario-42")

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .delete)
        #expect(request.path == "/scenarios/scenario-42")
        #expect(request.protected == true)
        #expect(request.body == nil)
    }

    @Test
    func deleteScenarioPropagatesClientError() async {
        client.response = .error(HubAPIError.forbidden)

        await #expect(throws: HubAPIError.forbidden) {
            try await service.deleteScenario(scenarioId: "scenario-42")
        }
    }

    // MARK: - helpers

    private static let emptyPage = Page<Scenario>(items: [], page: 1, pageSize: 20, totalPages: 1, totalItems: 0)

    private static let payload = ScenarioPayload(
        name: "Warm light on",
        description: nil,
        group: "living_room",
        active: true,
        trigger: ScenarioTrigger(
            sources: [.cron(ScenarioCronTrigger(cron: "8 21 * * *", adjustTo: .sunset))],
            logic: "1"
        ),
        actions: [
            ScenarioAction(externalId: "device-1", set: ScenarioActionSet(controls: ["on": AnyCodable(true)]))
        ]
    )

    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }
}
