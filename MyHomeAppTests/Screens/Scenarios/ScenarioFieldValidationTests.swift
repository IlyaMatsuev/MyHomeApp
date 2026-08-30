import Foundation
import Testing
@testable import MyHomeApp

struct ScenarioDraftFieldErrorTests {
    private func draft(name: String = "Movie time", description: String = "", group: String = "") -> ScenarioDraft {
        var draft = ScenarioDraft()
        draft.name = name
        draft.description = description
        draft.group = group
        return draft
    }

    // MARK: - error(for:)

    @Test(arguments: ["", "ab", String(repeating: "a", count: 81)])
    func aNameOutsideTheHubsRangeIsRejected(_ name: String) {
        #expect(draft(name: name).error(for: .name) != nil)
    }

    @Test(arguments: ["abc", String(repeating: "a", count: 80)])
    func aNameInsideTheHubsRangeIsAccepted(_ name: String) {
        #expect(draft(name: name).error(for: .name) == nil)
    }

    @Test
    func anEmptyDescriptionIsAccepted() {
        #expect(draft(description: "   ").error(for: .description) == nil)
    }

    @Test(arguments: ["too short", String(repeating: "a", count: 256)])
    func aDescriptionOutsideTheHubsRangeIsRejected(_ description: String) {
        #expect(draft(description: description).error(for: .description) != nil)
    }

    @Test
    func anEmptyGroupIsAccepted() {
        #expect(draft(group: "").error(for: .group) == nil)
    }

    @Test(arguments: ["ab", "12", "kitchen!", String(repeating: "a", count: 41)])
    func aGroupTheHubWouldRejectIsRejected(_ group: String) {
        #expect(draft(group: group).error(for: .group) != nil)
    }

    @Test
    func aGroupTypedAsALabelIsAccepted() {
        #expect(draft(group: "Living Room").error(for: .group) == nil, "It reaches the hub as living_room")
    }

    // MARK: - exceedsLimit(_:)

    @Test
    func aFieldUnderItsMaximumDoesNotExceedTheLimit() {
        let draft = draft(name: "ab", description: "short", group: "ab")

        #expect(!draft.exceedsLimit(.name), "Too short is still not too long")
        #expect(!draft.exceedsLimit(.description))
        #expect(!draft.exceedsLimit(.group))
    }

    @Test
    func aFieldOverItsMaximumExceedsTheLimit() {
        let draft = draft(
            name: String(repeating: "a", count: 81),
            description: String(repeating: "a", count: 256),
            group: String(repeating: "a", count: 41)
        )

        #expect(draft.exceedsLimit(.name))
        #expect(draft.exceedsLimit(.description))
        #expect(draft.exceedsLimit(.group))
    }

    // MARK: - fieldError / structureError

    @Test
    func fieldErrorsComeInFormOrder() {
        var draft = draft(name: "ab", description: "short")

        #expect(draft.fieldError == draft.error(for: .name))

        draft.name = "Movie time"
        #expect(draft.fieldError == draft.error(for: .description))
    }

    @Test
    func structureErrorIgnoresTheTextFields() {
        let draft = draft(name: "ab")

        #expect(draft.structureError == "Add at least one trigger.", "A short name is not a structure problem")
    }

    @Test
    func validationErrorPrefersAFieldProblem() {
        let draft = draft(name: "ab")

        #expect(draft.validationError == draft.error(for: .name))
        #expect(!draft.isValid)
    }
}

@MainActor
struct ScenarioEditorFieldErrorTests {
    private func makeViewModel(draft: ScenarioDraft = ScenarioDraft()) -> ScenarioEditorViewModel {
        ScenarioEditorViewModel(
            mode: .create,
            draft: draft,
            devices: [],
            knownGroups: [],
            knownCommands: [],
            service: StubScenarioService()
        ) { _ in }
    }

    // MARK: - Before the first save attempt

    @Test
    func anUntouchedEditorComplainsAboutNothing() {
        let viewModel = makeViewModel()

        #expect(ScenarioTextField.allCases.allSatisfy { viewModel.error(for: $0) == nil })
    }

    @Test
    func aHalfTypedNameIsNotComplainedAboutYet() {
        let viewModel = makeViewModel()
        viewModel.draft.name = "Mo"

        #expect(viewModel.error(for: .name) == nil, "More typing can still fix it")
    }

    @Test
    func anOverlongNameIsComplainedAboutWhileTyping() {
        let viewModel = makeViewModel()
        viewModel.draft.name = String(repeating: "a", count: 81)

        #expect(viewModel.error(for: .name) != nil, "More typing cannot fix it")
        #expect(!viewModel.canSave)
    }

    @Test
    func anOverlongGroupIsComplainedAboutWhileTyping() {
        let viewModel = makeViewModel()
        viewModel.draft.group = String(repeating: "a", count: 41)

        #expect(viewModel.error(for: .group) != nil)
    }

    @Test
    func anOverlongFieldStopsComplainingOnceTrimmedBack() {
        let viewModel = makeViewModel()
        viewModel.draft.name = String(repeating: "a", count: 81)
        viewModel.draft.name = "Movie time"

        #expect(viewModel.error(for: .name) == nil)
    }

    // MARK: - After a save attempt

    @Test
    func aSaveAttemptRevealsTheShortFields() async {
        let viewModel = makeViewModel()
        viewModel.draft.name = "Mo"
        viewModel.draft.description = "short"

        await viewModel.save()

        #expect(viewModel.error(for: .name) != nil)
        #expect(viewModel.error(for: .description) != nil)
    }

    @Test
    func aSaveAttemptKeepsQuietAboutAcceptableFields() async {
        let viewModel = makeViewModel()
        viewModel.draft.name = "Movie time"

        await viewModel.save()

        #expect(viewModel.error(for: .name) == nil)
        #expect(viewModel.error(for: .description) == nil, "An empty description is allowed")
        #expect(viewModel.error(for: .group) == nil, "An empty group is allowed")
    }

    @Test
    func theSummaryLineCoversOnlyWhatTheFieldsCannotShow() async {
        let viewModel = makeViewModel()
        viewModel.draft.name = "Mo"

        await viewModel.save()

        #expect(viewModel.validationMessage == "Add at least one trigger.")
    }
}
