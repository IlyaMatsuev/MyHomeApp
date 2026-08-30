import Testing
@testable import MyHomeApp

/// `ScenarioDraft.validationError` mirrors the hub's own rules, so a draft the editor accepts
/// cannot come back as a validation error.
struct ScenarioDraftValidationTests {
    // MARK: - validation

    @Test
    func aDraftNeedsANameATriggerAndAnAction() {
        var draft = ScenarioDraft()
        draft.sources = [ScenarioSourceDraft(kind: .cron)]
        draft.actions = [ScenarioActionDraft(deviceId: "plug-1")]
        #expect(!draft.isValid, "A nameless scenario is not valid")

        draft.name = "Movie time"
        #expect(draft.isValid)

        draft.sources = []
        #expect(!draft.isValid, "A scenario without a trigger would never fire")
    }

    @Test
    func aDraftWithAnIncompleteSourceIsInvalid() {
        var draft = ScenarioDraft()
        draft.name = "Movie time"
        draft.sources = [ScenarioSourceDraft(kind: .cron, cron: "  ")]
        draft.actions = [ScenarioActionDraft(deviceId: "plug-1")]

        #expect(!draft.isValid)
    }

    @Test
    func aDeviceSourceNeedsADeviceAndACommandValue() {
        var source = ScenarioSourceDraft(kind: .device, matchKind: .command, matchKey: "action")
        #expect(!source.isValid, "No device is selected yet")

        source.deviceId = "remote-1"
        #expect(!source.isValid, "A command match without a value matches nothing")

        source.matchText = "up_press"
        #expect(source.isValid)
    }

    // MARK: - validation against the hub's own rules

    @Test
    func aNameShorterThanTheHubMinimumIsRejected() {
        var draft = Self.completeDraft()
        draft.name = "Hi"

        #expect(draft.validationError?.contains("Name") == true)
    }

    @Test
    func aDescriptionShorterThanTheHubMinimumIsRejected() {
        var draft = Self.completeDraft()
        draft.description = "Too short"

        #expect(draft.validationError?.contains("Description") == true)
        draft.description = ""
        #expect(draft.isValid, "An empty description is simply omitted")
    }

    @Test
    func aGroupNameTheHubWouldRejectIsRejected() {
        var draft = Self.completeDraft()
        draft.group = "Living Room!"

        #expect(draft.validationError?.contains("Group") == true)

        draft.group = "Living Room"
        #expect(draft.isValid, "Spaces become underscores, so the hub gets \"living_room\"")
    }

    @Test
    func aSecondScheduleTriggerIsRejected() {
        var draft = Self.completeDraft()
        draft.sources.append(ScenarioSourceDraft(kind: .cron, cron: "0 20 * * *"))

        #expect(draft.validationError?.contains("one schedule trigger") == true)
    }

    @Test
    func aCustomExpressionThatSkipsATriggerIsRejected() {
        var draft = Self.completeDraft()
        draft.sources.append(ScenarioSourceDraft(kind: .device, deviceId: "plug-1"))
        draft.logicMode = .custom
        draft.customLogic = "1"

        #expect(!draft.isValid)

        draft.customLogic = "1 OR 2"
        #expect(draft.isValid)
    }

    private static func completeDraft() -> ScenarioDraft {
        var draft = ScenarioDraft()
        draft.name = "Movie time"
        draft.sources = [ScenarioSourceDraft(kind: .cron)]
        draft.actions = [ScenarioActionDraft(deviceId: "plug-1")]
        return draft
    }
}
