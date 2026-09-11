import Observation

@Observable
@MainActor
final class ScenariosRouter {
    enum Destination: Identifiable, Hashable {
        case create
        case edit(scenarioId: String)

        var id: String {
            switch self {
            case .create: "create"
            case .edit(let scenarioId): "edit-\(scenarioId)"
            }
        }
    }

    var destination: Destination?

    func createScenario() {
        destination = .create
    }

    func editScenario(_ scenario: Scenario) {
        destination = .edit(scenarioId: scenario.id)
    }

    func dismiss() {
        destination = nil
    }
}
