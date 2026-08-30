protocol ScenarioService: Sendable {
    func fetchScenarios() async throws -> Page<Scenario>
    func createScenario(payload: ScenarioPayload) async throws -> Scenario
    func updateScenario(scenarioId: String, payload: ScenarioPayload) async throws -> Scenario
    func setActive(scenarioId: String, active: Bool) async throws -> Scenario
    func deleteScenario(scenarioId: String) async throws
}
