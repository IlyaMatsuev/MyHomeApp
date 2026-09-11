import Testing
@testable import MyHomeApp

/// Navigation state for the scenarios tab: which destination is presented, and clearing it.
@MainActor
struct ScenariosRouterTests {
    private let router = ScenariosRouter()

    @Test
    func startsWithNoDestination() {
        #expect(router.destination == nil)
    }

    @Test
    func creatingSetsTheCreateDestination() {
        router.createScenario()

        #expect(router.destination == .create)
    }

    @Test
    func editingAScenarioSetsTheEditDestination() {
        let scenario = Scenario.fixture(name: "Movie time").build()

        router.editScenario(scenario)

        #expect(router.destination == .edit(scenarioId: scenario.id))
    }

    @Test
    func dismissingClearsTheDestination() {
        router.createScenario()

        router.dismiss()

        #expect(router.destination == nil)
    }
}
