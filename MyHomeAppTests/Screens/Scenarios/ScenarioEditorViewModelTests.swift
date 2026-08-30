import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

private enum Fixtures {
    static let lamp = Device.fixture(name: "Lamp")
        .withControls(["on": AnyCodable(false), "brightness": AnyCodable(80)])
        .build()

    static let speaker = Device.fixture(name: "Speaker").build()

    static let thermostat = Device.fixture(name: "Thermostat")
        .withMeasurements(["temperature": AnyCodable(21), "humidity": AnyCodable(40)])
        .build()
}

@MainActor
struct ScenarioEditorViewModelTests {
    private let service: StubScenarioService
    private let recorder: SavedScenarioRecorder

    init() {
        service = StubScenarioService()
        recorder = SavedScenarioRecorder()
    }

    @MainActor
    private final class SavedScenarioRecorder {
        private(set) var saved: [Scenario] = []

        func record(_ scenario: Scenario) {
            saved.append(scenario)
        }
    }

    private struct SampleError: LocalizedError {
        var errorDescription: String? { "Boom" }
    }

    private func makeViewModel(
        mode: ScenarioEditorViewModel.Mode = .create,
        draft: ScenarioDraft = ScenarioDraft(),
        devices: [Device] = [Fixtures.lamp, Fixtures.speaker],
        knownCommands: [ScenarioKnownCommand] = []
    ) -> ScenarioEditorViewModel {
        ScenarioEditorViewModel(
            mode: mode,
            draft: draft,
            devices: devices,
            knownGroups: ["living_room"],
            knownCommands: knownCommands,
            service: service
        ) { [recorder] scenario in
            recorder.record(scenario)
        }
    }

    private func validDraft(name: String = "Movie time") -> ScenarioDraft {
        var draft = ScenarioDraft()
        draft.name = name
        draft.sources = [ScenarioSourceDraft(kind: .cron, cron: "0 20 * * *")]
        draft.actions = [ScenarioActionDraft(deviceId: Fixtures.lamp.externalId)]
        return draft
    }

    // MARK: - canSave

    @Test
    func anEmptyDraftCannotBeSaved() {
        #expect(!makeViewModel().canSave)
    }

    @Test
    func aCompleteDraftCanBeSaved() {
        #expect(makeViewModel(draft: validDraft()).canSave)
    }

    @Test
    func aDraftWithoutActionsCannotBeSaved() {
        var draft = validDraft()
        draft.actions = []

        #expect(!makeViewModel(draft: draft).canSave)
    }

    @Test
    func aDraftWithAnInvalidCustomExpressionCannotBeSaved() {
        var draft = validDraft()
        draft.sources = [ScenarioSourceDraft(kind: .cron), ScenarioSourceDraft(kind: .cron)]
        draft.logicMode = .custom
        draft.customLogic = "1 AND 5"

        #expect(!makeViewModel(draft: draft).canSave)
    }

    // MARK: - logicErrorMessage

    @Test
    func logicErrorMessageIsSilentUntilTheExpressionIsBothCustomAndWrong() {
        var draft = validDraft()
        draft.sources = [ScenarioSourceDraft(kind: .cron), ScenarioSourceDraft(kind: .cron)]

        #expect(makeViewModel(draft: draft).logicErrorMessage == nil)

        draft.logicMode = .custom
        draft.customLogic = "1 AND 2"
        #expect(makeViewModel(draft: draft).logicErrorMessage == nil)

        draft.customLogic = "1 AND"
        #expect(makeViewModel(draft: draft).logicErrorMessage != nil)
    }

    // MARK: - showsLogicEditor

    @Test
    func logicEditorIsHiddenUntilThereIsSomethingToCombine() {
        var draft = validDraft()
        #expect(!makeViewModel(draft: draft).showsLogicEditor, "One trigger combines with nothing")

        draft.sources.append(ScenarioSourceDraft(kind: .cron))
        #expect(makeViewModel(draft: draft).showsLogicEditor)
    }

    @Test
    func logicEditorStaysReachableForACustomExpressionOverASingleSource() {
        let scenario = Scenario.fixture(name: "Warm light on")
            .withCron("8 21 * * *")
            .withDeviceControl(deviceId: "plug-1", value: false)
            .withLogic("(1 OR 2) AND 1")
            .withAction(deviceId: "plug-1", value: true)
            .build()
        var draft = ScenarioDraft(scenario: scenario)
        #expect(draft.logicMode == .custom)

        draft.sources.removeLast()
        let viewModel = makeViewModel(draft: draft)

        #expect(!viewModel.canSave, "The expression still references trigger 2, which is gone")
        #expect(
            viewModel.showsLogicEditor,
            "Hiding the expression here would strand the draft: unsaveable with no way to fix it"
        )
        #expect(viewModel.logicErrorMessage != nil)
    }

    // MARK: - save() — validation gate

    @Test
    func saveWithAnIncompleteDraftRevealsTheFieldErrorsAndCallsNothing() async {
        let viewModel = makeViewModel()

        await viewModel.save()

        #expect(viewModel.didAttemptSave)
        #expect(viewModel.error(for: .name) != nil, "The empty name is worth complaining about once Save is tried")
        #expect(service.createScenarioPayloads.isEmpty)
        #expect(recorder.saved.isEmpty)
    }

    // MARK: - save() — create

    @Test
    func saveInCreateModePostsTheDraftAsAPayload() async throws {
        let created = Scenario.fixture(name: "Movie time").build()
        service.createScenarioResult = .success(created)
        var draft = validDraft()
        draft.description = "  Dim the lights  "
        draft.group = "Living Room"
        let viewModel = makeViewModel(draft: draft)

        await viewModel.save()

        let payload = try #require(service.createScenarioPayloads.first)
        #expect(payload.name == "Movie time")
        #expect(payload.description == "Dim the lights")
        #expect(payload.group == "living_room")
        #expect(payload.active == true)
        #expect(payload.trigger.logic == "1")
        #expect(payload.actions.count == 1)
        #expect(service.updateScenarioCalls.isEmpty)
    }

    @Test
    func saveInCreateModeHandsTheSavedScenarioBack() async {
        let created = Scenario.fixture(name: "Movie time").build()
        service.createScenarioResult = .success(created)
        let viewModel = makeViewModel(draft: validDraft())

        await viewModel.save()

        #expect(recorder.saved == [created])
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - save() — update

    @Test
    func saveInEditModePutsAgainstTheScenarioId() async throws {
        let updated = Scenario.fixture(name: "Movie night").build()
        service.updateScenarioResult = .success(updated)
        let viewModel = makeViewModel(mode: .edit("scenario-42"), draft: validDraft(name: "Movie night"))

        await viewModel.save()

        let call = try #require(service.updateScenarioCalls.first)
        #expect(call.scenarioId == "scenario-42")
        #expect(call.payload.name == "Movie night")
        #expect(service.createScenarioPayloads.isEmpty)
        #expect(recorder.saved == [updated])
    }

    // MARK: - save() — failure

    @Test
    func saveSurfacesHubFailuresAndKeepsTheSheetOpen() async {
        service.createScenarioResult = .failure(HubAPIError.validation("name", "Name is taken"))
        let viewModel = makeViewModel(draft: validDraft())

        await viewModel.save()

        #expect(viewModel.errorMessage == "Name is taken")
        #expect(recorder.saved.isEmpty)
        #expect(!viewModel.loading)
    }

    @Test
    func saveMapsUnknownFailuresToAGenericMessage() async {
        service.createScenarioResult = .failure(SampleError())
        let viewModel = makeViewModel(draft: validDraft())

        await viewModel.save()

        #expect(viewModel.errorMessage == ScenarioError.generic)
    }

    // MARK: - trigger source editing

    @Test
    func addSourceAppendsACronTriggerWithADefaultExpression() throws {
        let viewModel = makeViewModel()

        viewModel.addSource(kind: .cron)

        let source = try #require(viewModel.draft.sources.first)
        #expect(source.kind == .cron)
        #expect(!source.cron.isEmpty)
        #expect(source.isValid)
    }

    @Test
    func addSourcePreselectsTheFirstDeviceAndItsToggleControl() throws {
        let viewModel = makeViewModel()

        viewModel.addSource(kind: .device)

        let source = try #require(viewModel.draft.sources.first)
        #expect(source.deviceId == Fixtures.lamp.externalId)
        #expect(source.matchKey == "on")
        #expect(source.isValid)
    }

    @Test
    func removeSourceDropsOnlyThatSource() throws {
        let viewModel = makeViewModel()
        viewModel.addSource(kind: .cron)
        viewModel.addSource(kind: .device)
        let first = try #require(viewModel.draft.sources.first)

        viewModel.removeSource(first)

        #expect(viewModel.draft.sources.count == 1)
        #expect(viewModel.draft.sources.first?.kind == .device)
    }

    @Test
    func selectDeviceForASourceResetsTheControlKeyToOneTheDeviceHas() throws {
        let viewModel = makeViewModel()
        viewModel.addSource(kind: .device)
        let source = try #require(viewModel.draft.sources.first)

        viewModel.selectDevice(Fixtures.speaker.externalId, forSource: source)

        let updated = try #require(viewModel.draft.sources.first)
        #expect(updated.deviceId == Fixtures.speaker.externalId)
        #expect(updated.matchKey == "on", "A device without known controls falls back to the default key")
    }

    @Test
    func selectMatchKindSwapsTheDefaultKey() throws {
        let viewModel = makeViewModel()
        viewModel.addSource(kind: .device)
        let source = try #require(viewModel.draft.sources.first)

        viewModel.selectMatchKind(.command, forSource: source)

        let asCommand = try #require(viewModel.draft.sources.first)
        #expect(asCommand.matchKind == .command)
        #expect(asCommand.matchKey == "action")

        viewModel.selectMatchKind(.control, forSource: asCommand)

        let asControl = try #require(viewModel.draft.sources.first)
        #expect(asControl.matchKind == .control)
        #expect(asControl.matchKey == "on")
    }

    // MARK: - trigger source values

    @Test
    func addSourceStartsFromTheControlValueTheDeviceReports() throws {
        let viewModel = makeViewModel()

        viewModel.addSource(kind: .device)

        let source = try #require(viewModel.draft.sources.first)
        #expect(source.matchValue == false, "The lamp reports \"on\": false")
    }

    @Test
    func selectMatchKindStartsFromTheMeasurementValueTheDeviceReports() throws {
        let viewModel = makeViewModel(devices: [Fixtures.thermostat])
        viewModel.addSource(kind: .device)
        let source = try #require(viewModel.draft.sources.first)

        viewModel.selectMatchKind(.measurement, forSource: source)

        let updated = try #require(viewModel.draft.sources.first)
        #expect(updated.matchKey == "humidity")
        #expect(updated.matchText == "40")
    }

    @Test
    func selectMatchKeyRefreshesTheValueOfTheNewKey() throws {
        let viewModel = makeViewModel(devices: [Fixtures.thermostat])
        viewModel.addSource(kind: .device)
        let source = try #require(viewModel.draft.sources.first)
        viewModel.selectMatchKind(.measurement, forSource: source)
        let measurement = try #require(viewModel.draft.sources.first)

        viewModel.selectMatchKey("temperature", forSource: measurement)

        let updated = try #require(viewModel.draft.sources.first)
        #expect(updated.matchKey == "temperature")
        #expect(updated.matchText == "21")
    }

    @Test
    func selectMatchKindStartsFromACommandAnotherScenarioAlreadyUses() throws {
        let known = ScenarioKnownCommand(deviceId: Fixtures.lamp.externalId, name: "action", value: "up_press")
        let viewModel = makeViewModel(knownCommands: [known])
        viewModel.addSource(kind: .device)
        let source = try #require(viewModel.draft.sources.first)

        viewModel.selectMatchKind(.command, forSource: source)

        let updated = try #require(viewModel.draft.sources.first)
        #expect(updated.matchKey == "action")
        #expect(updated.matchText == "up_press")
        #expect(updated.isValid)
    }

    @Test
    func selectMatchKindLeavesTheCommandValueEmptyWhenNoneIsKnown() throws {
        let viewModel = makeViewModel()
        viewModel.addSource(kind: .device)
        let source = try #require(viewModel.draft.sources.first)

        viewModel.selectMatchKind(.command, forSource: source)

        let updated = try #require(viewModel.draft.sources.first)
        #expect(updated.matchText.isEmpty)
    }

    // MARK: - action editing

    @Test
    func addActionPreselectsTheFirstDeviceAndItsToggleControl() throws {
        let viewModel = makeViewModel()

        viewModel.addAction()

        let action = try #require(viewModel.draft.actions.first)
        #expect(action.deviceId == Fixtures.lamp.externalId)
        #expect(action.controlKey == "on")
        #expect(action.isValid)
    }

    @Test
    func removeActionDropsOnlyThatAction() throws {
        let viewModel = makeViewModel()
        viewModel.addAction()
        viewModel.addAction()
        let first = try #require(viewModel.draft.actions.first)

        viewModel.removeAction(first)

        #expect(viewModel.draft.actions.count == 1)
        #expect(viewModel.draft.actions.first?.id != first.id)
    }

    // MARK: - control key discovery

    @Test
    func toggleControlKeysOnlyOffersBooleanControls() {
        let viewModel = makeViewModel()

        #expect(viewModel.toggleControlKeys(ofDeviceId: Fixtures.lamp.externalId) == ["on"])
    }

    @Test
    func toggleControlKeysForAnUnknownDeviceIsEmpty() {
        let viewModel = makeViewModel()

        #expect(viewModel.toggleControlKeys(ofDeviceId: "nope").isEmpty)
    }
}
