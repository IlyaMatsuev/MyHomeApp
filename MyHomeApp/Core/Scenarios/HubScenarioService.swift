struct HubScenarioService: ScenarioService {
    private struct UpdateActiveRequest: Encodable {
        let active: Bool
    }

    private let client: MyHomeAPIClient

    init(client: MyHomeAPIClient) {
        self.client = client
    }

    func fetchScenarios() async throws -> [Scenario] {
        let request = HubRequest.get("/scenarios", ["all": "true", "includeInactive": "true"])
        let page: Page<Scenario> = try await client.send(request)
        return page.items
    }

    func createScenario(payload: ScenarioPayload) async throws -> Scenario {
        let request = try HubRequest.post("/scenarios", payload)
        return try await client.send(request)
    }

    func updateScenario(scenarioId: String, payload: ScenarioPayload) async throws -> Scenario {
        let request = try HubRequest.put("/scenarios/\(scenarioId)", payload)
        return try await client.send(request)
    }

    func setActive(scenarioId: String, active: Bool) async throws -> Scenario {
        let request = try HubRequest.put("/scenarios/\(scenarioId)", UpdateActiveRequest(active: active))
        return try await client.send(request)
    }

    func deleteScenario(scenarioId: String) async throws {
        let request = HubRequest.delete("/scenarios/\(scenarioId)")
        try await client.send(request)
    }
}
