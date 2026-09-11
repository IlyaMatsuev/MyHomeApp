import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct ScenariosViewModelTests {
    private let service: StubScenarioService
    private let deviceService: StubDeviceService
    private let toastStore: ToastStore
    private let viewModel: ScenariosViewModel

    init() {
        service = StubScenarioService()
        deviceService = StubDeviceService()
        toastStore = ToastStore()
        viewModel = ScenariosViewModel(service: service, deviceService: deviceService, toastStore: toastStore)
    }

    private struct SampleError: LocalizedError {
        var errorDescription: String? { "Boom" }
    }

    // MARK: - init

    @Test
    func initDefaultSelectedGroupIsAll() {
        #expect(viewModel.selectedGroup == .all)
    }

    @Test
    func initHonorsSelectedGroupOverride() {
        let viewModel = ScenariosViewModel(
            service: service,
            deviceService: deviceService,
            toastStore: toastStore,
            selectedGroup: .named("kitchen")
        )

        #expect(viewModel.selectedGroup == .named("kitchen"))
    }

    // MARK: - load() — state transitions

    @Test
    func loadWhenServiceSucceedsSetsLoadedState() async {
        service.setScenarios([Scenario.fixture(name: "Warm light on").build()])

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.scenarios.count == 1)
        #expect(service.fetchScenariosCallCount == 1)
    }

    /// An initial load has no content to keep, so the failure is shown inline and *not* also
    /// duplicated as a toast.
    @Test
    func loadWhenServiceFailsSetsFailedStateWithoutAToast() async {
        service.setScenariosError(SampleError())

        await viewModel.load()

        #expect(viewModel.state == .failed(ScenarioError.generic))
        #expect(viewModel.scenarios.isEmpty)
        #expect(toastStore.current == nil)
    }

    @Test
    func loadWhenTheHubRejectsTheRequestShowsTheHubWording() async {
        service.setScenariosError(HubAPIError.unauthorized)

        await viewModel.load()

        #expect(viewModel.state == .failed(ScenarioError.text(for: HubAPIError.unauthorized)))
    }

    @Test
    func loadWithEmptyResponseSetsLoadedWithNoScenarios() async {
        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.groupSections.isEmpty)
    }

    // MARK: - load() — devices are a best-effort side load

    @Test
    func loadAlsoLoadsDevicesForTheEditor() async {
        deviceService.setDevices([Device.fixture(name: "Lamp").build()])

        await viewModel.load()

        #expect(viewModel.devices.count == 1)
    }

    @Test
    func loadKeepsScenariosWhenTheDeviceRequestFails() async {
        service.setScenarios([Scenario.fixture(name: "Warm light on").build()])
        deviceService.setDevicesError(SampleError())

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.scenarios.count == 1)
        #expect(viewModel.devices.isEmpty)
    }

    // MARK: - setActive()

    @Test
    func setActiveSendsTheNewValueAndKeepsTheServerResponse() async throws {
        let scenario = Scenario.fixture(name: "Movie time", active: true).build()
        var updated = scenario
        updated.active = false
        service.setScenarios([scenario])
        service.setActiveResult = { _, _ in .success(updated) }
        await viewModel.load()

        await viewModel.setActive(scenario, to: false)

        let call = try #require(service.setActiveCalls.first)
        #expect(call.scenarioId == scenario.externalId)
        #expect(call.active == false)
        let stored = try #require(viewModel.scenarios.first)
        #expect(stored.active == false)
        #expect(!viewModel.isBusy(scenario))
    }

    @Test
    func setActiveRollsBackWhenTheHubRejectsIt() async throws {
        let scenario = Scenario.fixture(name: "Movie time", active: true).build()
        service.setScenarios([scenario])
        service.setActiveResult = { _, _ in .failure(SampleError()) }
        await viewModel.load()

        await viewModel.setActive(scenario, to: false)

        let stored = try #require(viewModel.scenarios.first)
        #expect(stored.active == true, "A failed toggle must restore the previous value")
        let toast = try #require(toastStore.current)
        #expect(toast.kind == .error)
        #expect(!viewModel.isBusy(scenario))
    }

    // MARK: - deletion

    @Test
    func requestDeletionOnlyMarksTheScenarioAndCallsNothing() async {
        let scenario = Scenario.fixture(name: "Movie time").build()
        service.setScenarios([scenario])
        await viewModel.load()

        viewModel.requestDeletion(of: scenario)

        #expect(viewModel.scenarioPendingDeletion == scenario)
        #expect(service.deletedScenarioIds.isEmpty)
        #expect(viewModel.scenarios.count == 1)
    }

    @Test
    func cancelDeletionClearsThePendingScenario() async {
        let scenario = Scenario.fixture(name: "Movie time").build()
        service.setScenarios([scenario])
        await viewModel.load()
        viewModel.requestDeletion(of: scenario)

        viewModel.cancelDeletion()

        #expect(viewModel.scenarioPendingDeletion == nil)
    }

    @Test
    func confirmDeletionRemovesTheScenario() async {
        let scenario = Scenario.fixture(name: "Movie time").build()
        service.setScenarios([scenario])
        await viewModel.load()
        viewModel.requestDeletion(of: scenario)

        await viewModel.confirmDeletion(of: scenario)

        #expect(service.deletedScenarioIds == [scenario.externalId])
        #expect(viewModel.scenarios.isEmpty)
        #expect(viewModel.scenarioPendingDeletion == nil)
    }

    @Test
    func confirmDeletionKeepsTheScenarioWhenTheHubFails() async throws {
        let scenario = Scenario.fixture(name: "Movie time").build()
        service.setScenarios([scenario])
        service.deleteScenarioError = SampleError()
        await viewModel.load()
        viewModel.requestDeletion(of: scenario)

        await viewModel.confirmDeletion(of: scenario)

        #expect(viewModel.scenarios.count == 1)
        let toast = try #require(toastStore.current)
        #expect(toast.kind == .error)
        #expect(!viewModel.isBusy(scenario))
    }

    /// Dismissing the dialog clears `scenarioPendingDeletion` before the button's action runs,
    /// so the delete must not depend on it still being set.
    @Test
    func confirmDeletionStillDeletesWhenThePendingScenarioWasAlreadyCleared() async {
        let scenario = Scenario.fixture(name: "Movie time").build()
        service.setScenarios([scenario])
        await viewModel.load()
        viewModel.requestDeletion(of: scenario)
        viewModel.cancelDeletion()

        await viewModel.confirmDeletion(of: scenario)

        #expect(service.deletedScenarioIds == [scenario.externalId])
        #expect(viewModel.scenarios.isEmpty)
    }

    // MARK: - knownCommands

    @Test
    func knownCommandsOfferTheCommandMatchesOtherScenariosUse() async {
        service.setScenarios([
            Scenario.fixture(name: "Warm light on")
                .withDeviceCommand(deviceId: "device-1", value: "up_press")
                .build()
        ])

        await viewModel.load()

        #expect(
            viewModel.knownCommands == [
                ScenarioKnownCommand(deviceId: "device-1", name: "action", value: "up_press")
            ]
        )
    }

    // MARK: - mergeScenario()

    /// The editor the destination view would build for this list: same inputs, and a save merges
    /// straight back into the list.
    private func editorViewModel(mode: ScenarioEditorViewModel.Mode, draft: ScenarioDraft) -> ScenarioEditorViewModel {
        ScenarioEditorViewModel(
            mode: mode,
            draft: draft,
            devices: viewModel.devices,
            knownGroups: viewModel.knownGroups,
            knownCommands: viewModel.knownCommands,
            service: service,
            onChanged: { [viewModel] saved in viewModel.mergeScenario(saved) }
        )
    }

    @Test
    func savingAnEditedScenarioReplacesItInTheList() async {
        let scenario = Scenario.fixture(name: "Movie time").inGroup("living_room").build()
        var renamed = Scenario.fixture(name: "Movie night").inGroup("living_room").build()
        renamed = Scenario(
            externalId: scenario.externalId,
            name: renamed.name,
            trigger: renamed.trigger,
            actions: renamed.actions,
            active: renamed.active,
            group: renamed.group,
            createdAt: renamed.createdAt,
            updatedAt: renamed.updatedAt
        )
        service.setScenarios([scenario])
        service.updateScenarioResult = .success(renamed)
        await viewModel.load()

        let editor = editorViewModel(mode: .edit(scenario.externalId), draft: ScenarioDraft(scenario: scenario))
        editor.draft.name = "Movie night"
        editor.draft.sources = [ScenarioSourceDraft(kind: .cron)]
        editor.draft.actions = [ScenarioActionDraft(deviceId: "device-1")]
        await editor.save()

        #expect(viewModel.scenarios.map(\.name) == ["Movie night"])
    }

    @Test
    func savingANewScenarioAppendsItToTheList() async {
        let created = Scenario.fixture(name: "Away mode").inGroup("office").build()
        service.setScenarios([Scenario.fixture(name: "Movie time").build()])
        service.createScenarioResult = .success(created)
        await viewModel.load()

        let editor = editorViewModel(mode: .create, draft: ScenarioDraft())
        editor.draft.name = "Away mode"
        editor.draft.sources = [ScenarioSourceDraft(kind: .cron)]
        editor.draft.actions = [ScenarioActionDraft(deviceId: "device-1")]
        await editor.save()

        #expect(viewModel.scenarios.map(\.name).sorted() == ["Away mode", "Movie time"])
    }
}
