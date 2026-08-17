import Foundation
import AnyCodable

struct MockScenarioService: ScenarioService {
    let operationDelay: Duration

    static var allScenarios: [Scenario] {
        let now = Date()
        return [
            Scenario(
                externalId: "d3ccf155-3ed5-459c-aec2-f37f6402f1a1",
                name: "Warm light on",
                description: "Switches on the warm light in the living room",
                trigger: ScenarioTrigger(
                    sources: [
                        .cron(ScenarioCronTrigger(cron: "8 21 * * *", adjustTo: .sunset)),
                        .device(
                            ScenarioDeviceTrigger(
                                externalId: "11111111-1111-1111-5555-111111111111",
                                commands: ScenarioValueMatch(are: ["action": "up_press"])
                            )
                        ),
                        .device(
                            ScenarioDeviceTrigger(
                                externalId: "11111111-1111-1111-3333-111111111111",
                                controls: ScenarioValueMatch(are: ["on": false])
                            )
                        )
                    ],
                    logic: "(1 OR 2) AND 3"
                ),
                actions: [
                    ScenarioAction(
                        externalId: "11111111-1111-1111-3333-111111111111",
                        set: ScenarioActionSet(controls: ["on": true])
                    )
                ],
                active: true,
                group: ScenarioGroup("living_room"),
                createdAt: now,
                updatedAt: now
            ),
            Scenario(
                externalId: "a1b2c3d4-0000-4000-8000-000000000001",
                name: "Everything off at night",
                description: "Turns the ceiling light off after midnight",
                trigger: ScenarioTrigger(
                    sources: [.cron(ScenarioCronTrigger(cron: "0 1 * * *"))],
                    logic: "1"
                ),
                actions: [
                    ScenarioAction(
                        externalId: "11111111-1111-1111-4444-111111111111",
                        set: ScenarioActionSet(controls: ["on": false])
                    )
                ],
                active: false,
                createdAt: now,
                updatedAt: now
            )
        ]
    }

    init(operationDelay: Duration = .seconds(1)) {
        self.operationDelay = operationDelay
    }

    func fetchScenarios() async throws -> Page<Scenario> {
        try await Task.sleep(for: operationDelay)
        let scenarios = Self.allScenarios
        return Page(
            items: scenarios,
            page: 1,
            pageSize: 20,
            totalPages: 1,
            totalItems: scenarios.count
        )
    }

    func createScenario(payload: ScenarioPayload) async throws -> Scenario {
        try await Task.sleep(for: operationDelay)
        return Self.make(from: payload, externalId: UUID().uuidString)
    }

    func updateScenario(scenarioId: String, payload: ScenarioPayload) async throws -> Scenario {
        try await Task.sleep(for: operationDelay)
        return Self.make(from: payload, externalId: scenarioId)
    }

    func setActive(scenarioId: String, active: Bool) async throws -> Scenario {
        guard let scenario = Self.allScenarios.first(where: { $0.externalId == scenarioId }) else {
            throw ScenarioNotFoundError(scenarioId: scenarioId)
        }

        try await Task.sleep(for: operationDelay)

        return Scenario(
            externalId: scenario.externalId,
            name: scenario.name,
            description: scenario.description,
            trigger: scenario.trigger,
            actions: scenario.actions,
            active: active,
            group: scenario.group,
            createdAt: scenario.createdAt,
            updatedAt: Date()
        )
    }

    func deleteScenario(scenarioId: String) async throws {
        guard Self.allScenarios.contains(where: { $0.externalId == scenarioId }) else {
            throw ScenarioNotFoundError(scenarioId: scenarioId)
        }
        try await Task.sleep(for: operationDelay)
    }

    private static func make(from payload: ScenarioPayload, externalId: String) -> Scenario {
        Scenario(
            externalId: externalId,
            name: payload.name,
            description: payload.description,
            trigger: payload.trigger,
            actions: payload.actions,
            active: payload.active,
            group: payload.group,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    struct ScenarioNotFoundError: LocalizedError {
        let scenarioId: String

        var errorDescription: String? {
            "Scenario with id \"\(scenarioId)\" was not found"
        }

        init(scenarioId: String) {
            self.scenarioId = scenarioId
        }
    }
}
