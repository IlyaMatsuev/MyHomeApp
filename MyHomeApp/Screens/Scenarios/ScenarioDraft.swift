import Foundation

/// Everything the scenario editor can change, in a shape SwiftUI can bind to.
///
/// `Scenario` is immutable and wire-shaped (enums with associated values, `AnyCodable` maps), which
/// makes it a poor form model. `ScenarioDraft` is the mutable mirror; `payload` converts it back.
struct ScenarioDraft: Hashable {
    var name: String
    var description: String
    var group: String
    var active: Bool

    var sources: [ScenarioSourceDraft]
    var actions: [ScenarioActionDraft]

    /// Switching to `custom` seeds the expression with the equivalent of the previous choice,
    /// so the user edits something meaningful instead of an empty field.
    var logicMode: ScenarioTriggerLogic.Mode {
        didSet {
            guard logicMode == .custom, customLogic.isBlank else { return }
            let previous: ScenarioTriggerLogic = oldValue == .any ? .any : .all
            customLogic = previous.expression(sourceCount: sources.count)
        }
    }

    var customLogic: String

    var logic: ScenarioTriggerLogic {
        switch logicMode {
        case .all: return .all
        case .any: return .any
        case .custom: return .custom(customLogic)
        }
    }

    /// What still stops the hub from accepting this draft, or `nil` when it is ready to send.
    /// The rules mirror the hub's own validation, so a valid draft cannot come back as a 400.
    var validationError: String? {
        if !ScenarioLimits.nameLength.contains(name.trimmed.count) {
            return "Name must be \(ScenarioLimits.nameLength.lowerBound)"
                + "–\(ScenarioLimits.nameLength.upperBound) characters."
        }
        if !description.isBlank, !ScenarioLimits.descriptionLength.contains(description.trimmed.count) {
            return "Description must be \(ScenarioLimits.descriptionLength.lowerBound)"
                + "–\(ScenarioLimits.descriptionLength.upperBound) characters, or left empty."
        }
        if !group.isBlank, !ScenarioGroupName.isValid(group.trimmed) {
            return "Group must be \(ScenarioLimits.groupNameLength.lowerBound)"
                + "–\(ScenarioLimits.groupNameLength.upperBound) letters, digits or underscores, and not digits only."
        }
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

    var isValid: Bool { validationError == nil }

    var payload: ScenarioPayload {
        ScenarioPayload(
            name: name.trimmed,
            description: description.isBlank ? nil : description.trimmed,
            group: group.isBlank ? nil : group.trimmed,
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
        group = scenario.group ?? ""
        active = scenario.active
        self.sources = sources
        actions = scenario.actions.map { ScenarioActionDraft(action: $0) }
        logicMode = logic.mode
        customLogic = logic.customExpression ?? ""
    }
}
