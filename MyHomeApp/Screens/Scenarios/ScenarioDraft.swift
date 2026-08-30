import Foundation

struct ScenarioDraft: Hashable {
    var name: String
    var description: String
    var group: String
    var active: Bool

    var sources: [ScenarioSourceDraft]
    var actions: [ScenarioActionDraft]

    var logicMode: ScenarioTriggerLogic.Mode {
        didSet {
            guard logicMode == .custom, customLogic.isBlank else { return }
            let previous: ScenarioTriggerLogic = oldValue == .any ? .any : .all
            customLogic = previous.expression(sourceCount: sources.count)
        }
    }

    var customLogic: String

    var logic: ScenarioTriggerLogic {
        ScenarioTriggerLogic(mode: logicMode, customExpression: customLogic)
    }

    var validationError: String? { fieldError ?? structureError }

    /// The first complaint about one of the editor's bounded text fields.
    var fieldError: String? {
        ScenarioTextField.allCases.lazy.compactMap { error(for: $0) }.first
    }

    /// What stops the hub from accepting the draft beyond the individual fields.
    var structureError: String? {
        if sources.isEmpty {
            return "Add at least one trigger."
        }
        if sources.filter({ $0.kind == .cron }).count > ScenarioLimits.maxCronSources {
            return "A scenario can only have one schedule trigger."
        }
        if !sources.allSatisfy(\.isValid) {
            return "Every trigger needs a complete schedule or device condition."
        }
        if actions.isEmpty {
            return "Add at least one action."
        }
        if !actions.allSatisfy(\.isValid) {
            return "Every action needs a device and a control."
        }
        if !logic.isValid(sourceCount: sources.count) {
            return "Combine the triggers with numbers 1–\(sources.count), AND and OR — each trigger exactly once."
        }
        return nil
    }

    /// Why the hub would reject this field, or `nil` when its value is acceptable.
    func error(for field: ScenarioTextField) -> String? {
        switch field {
        case .name:
            if ScenarioLimits.nameLength.contains(name.trimmed.count) { return nil }
            return "Name must be \(ScenarioLimits.nameLength.lowerBound)"
                + "–\(ScenarioLimits.nameLength.upperBound) characters."

        case .description:
            if description.isBlank { return nil }
            if ScenarioLimits.descriptionLength.contains(description.trimmed.count) { return nil }
            return "Description must be \(ScenarioLimits.descriptionLength.lowerBound)"
                + "–\(ScenarioLimits.descriptionLength.upperBound) characters, or left empty."

        case .group:
            if group.isBlank { return nil }
            if ScenarioGroupName.isValid(groupApiName) { return nil }
            return "Group must be \(ScenarioLimits.groupNameLength.lowerBound)"
                + "–\(ScenarioLimits.groupNameLength.upperBound) letters, digits or underscores, and not digits only."
        }
    }

    /// `true` once the field is past its maximum. More typing cannot fix that, so the editor
    /// complains straight away instead of waiting for a save.
    func exceedsLimit(_ field: ScenarioTextField) -> Bool {
        switch field {
        case .name: return name.trimmed.count > ScenarioLimits.nameLength.upperBound
        case .description: return description.trimmed.count > ScenarioLimits.descriptionLength.upperBound
        case .group: return groupApiName.count > ScenarioLimits.groupNameLength.upperBound
        }
    }

    var isValid: Bool { validationError == nil }

    var groupApiName: String { ScenarioGroupName.apiName(for: group.trimmed) }

    var payload: ScenarioPayload {
        ScenarioPayload(
            name: name.trimmed,
            description: description.isBlank ? nil : description.trimmed,
            group: group.isBlank ? nil : groupApiName,
            active: active,
            trigger: ScenarioTrigger(
                sources: sources.map(\.triggerSource),
                logic: logic.expression(sourceCount: sources.count)
            ),
            actions: actions.map(\.action)
        )
    }

    init() {
        name = ""
        description = ""
        group = ""
        active = true
        sources = []
        actions = []
        logicMode = .all
        customLogic = ""
    }

    init(scenario: Scenario) {
        let sources = scenario.trigger.sources.map { ScenarioSourceDraft(source: $0) }
        let logic = ScenarioTriggerLogic.parse(scenario.trigger.logic, sourceCount: sources.count)

        name = scenario.name
        description = scenario.description ?? ""
        group = scenario.group.map { ScenarioGroupName.label(for: $0) } ?? ""
        active = scenario.active
        self.sources = sources
        actions = scenario.actions.map { ScenarioActionDraft(action: $0) }
        logicMode = logic.mode
        customLogic = logic.customExpression ?? ""
    }
}
