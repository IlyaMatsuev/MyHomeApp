struct HubScenarioService: ScenarioService {
    private struct UpdateActiveRequest: Encodable {
        let active: Bool
    }

    private let client: MyHomeAPIClient

    init(client: MyHomeAPIClient) {
        self.client = client
    }

    // TODO: Need to figure out how to handle pagination
    func fetchScenarios() async throws -> Page<Scenario> {
        let request = HubRequest.get("/scenarios", ["pageSize": "20", "includeInactive": "true"])
        return try await client.send(request)
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
