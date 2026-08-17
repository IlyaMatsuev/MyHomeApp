import Foundation
@testable import MyHomeApp

final class StubScenarioService: ScenarioService, @unchecked Sendable {
    enum StubError: Error {
        case notConfigured
    }

    private(set) var fetchScenariosResult: Result<Page<Scenario>, Error> = .success(
        Page(items: [], page: 1, pageSize: 0, totalPages: 1, totalItems: 0)
    )

    var createScenarioResult: Result<Scenario, Error> = .failure(StubError.notConfigured)
    var updateScenarioResult: Result<Scenario, Error> = .failure(StubError.notConfigured)
    var setActiveResult: (String, Bool) -> Result<Scenario, Error> = { _, _ in .failure(StubError.notConfigured) }
    var deleteScenarioError: Error?

    private(set) var fetchScenariosCallCount = 0
    private(set) var createScenarioPayloads: [ScenarioPayload] = []
    private(set) var updateScenarioCalls: [(scenarioId: String, payload: ScenarioPayload)] = []
    private(set) var setActiveCalls: [(scenarioId: String, active: Bool)] = []
    private(set) var deletedScenarioIds: [String] = []

    func fetchScenarios() async throws -> Page<Scenario> {
        fetchScenariosCallCount += 1
        return try fetchScenariosResult.get()
    }

    func createScenario(payload: ScenarioPayload) async throws -> Scenario {
        createScenarioPayloads.append(payload)
        return try createScenarioResult.get()
    }

    func updateScenario(scenarioId: String, payload: ScenarioPayload) async throws -> Scenario {
        updateScenarioCalls.append((scenarioId, payload))
        return try updateScenarioResult.get()
    }

    func setActive(scenarioId: String, active: Bool) async throws -> Scenario {
        setActiveCalls.append((scenarioId, active))
        return try setActiveResult(scenarioId, active).get()
    }

    func deleteScenario(scenarioId: String) async throws {
        deletedScenarioIds.append(scenarioId)
        if let deleteScenarioError {
            throw deleteScenarioError
        }
    }

    func setScenarios(_ scenarios: [Scenario]) {
        fetchScenariosResult = .success(
            Page(
                items: scenarios,
                page: 1,
                pageSize: scenarios.count,
                totalPages: 1,
                totalItems: scenarios.count
            )
        )
    }

    func setScenariosError(_ error: Error) {
        fetchScenariosResult = .failure(error)
    }
}
