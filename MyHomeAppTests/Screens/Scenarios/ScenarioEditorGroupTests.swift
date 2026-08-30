import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct ScenarioEditorGroupTests {
    private let service = StubScenarioService()

    private func makeViewModel(knownGroups: [String] = ["living_room"]) -> ScenarioEditorViewModel {
        ScenarioEditorViewModel(
            mode: .create,
            draft: ScenarioDraft(),
            devices: [],
            knownGroups: knownGroups,
            knownCommands: [],
            service: service
        ) { _ in }
    }

    // MARK: - Adding a group

    @Test
    func addingATypedGroupOffersItAsAPill() {
        let viewModel = makeViewModel()
        viewModel.draft.group = "Kitchen"

        #expect(viewModel.canAddTypedGroup)
        viewModel.addTypedGroup()

        #expect(viewModel.knownGroups == ["kitchen", "living_room"], "New groups sort in with the known ones")
    }

    @Test
    func addingATypedGroupKeepsItSelected() {
        let viewModel = makeViewModel()
        viewModel.draft.group = "Kitchen"

        viewModel.addTypedGroup()

        #expect(viewModel.draft.group == "Kitchen", "The typed name stays in the field")
        #expect(viewModel.knownGroups.contains(viewModel.draft.groupApiName), "…so its pill reads as selected")
    }

    @Test
    func addingATypedGroupDoesNotCallTheHub() {
        let viewModel = makeViewModel()
        viewModel.draft.group = "Kitchen"

        viewModel.addTypedGroup()

        #expect(service.createScenarioPayloads.isEmpty)
        #expect(service.updateScenarioCalls.isEmpty)
        #expect(service.fetchScenariosCallCount == 0)
    }

    @Test
    func anAddedGroupReachesTheHubOnlyThroughTheSavedScenario() async throws {
        let viewModel = makeViewModel()
        viewModel.draft.name = "Movie time"
        viewModel.draft.sources = [ScenarioSourceDraft(kind: .cron, cron: "0 20 * * *")]
        viewModel.draft.actions = [ScenarioActionDraft(deviceId: "device-1")]
        viewModel.draft.group = "Kitchen"
        viewModel.addTypedGroup()
        service.createScenarioResult = .success(Scenario.fixture().build())

        await viewModel.save()

        let payload = try #require(service.createScenarioPayloads.first)
        #expect(payload.group == "kitchen")
    }

    // MARK: - When the button stays disabled

    @Test
    func aBlankGroupCannotBeAdded() {
        let viewModel = makeViewModel()

        #expect(!viewModel.canAddTypedGroup)
    }

    @Test
    func aGroupTheEditorAlreadyOffersCannotBeAddedTwice() {
        let viewModel = makeViewModel()
        viewModel.draft.group = "Living Room"

        #expect(!viewModel.canAddTypedGroup, "\"Living Room\" is already stored as \"living_room\"")
    }

    @Test(arguments: ["ab", "12", "kitchen!"])
    func aNameTheHubWouldRejectCannotBeAdded(_ group: String) {
        let viewModel = makeViewModel()
        viewModel.draft.group = group

        #expect(!viewModel.canAddTypedGroup)
    }

    @Test
    func addingIsIgnoredWhenTheNameIsNotAddable() {
        let viewModel = makeViewModel()
        viewModel.draft.group = "12"

        viewModel.addTypedGroup()

        #expect(viewModel.knownGroups == ["living_room"])
    }
}
