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

    var isValid: Bool {
        guard !name.isBlank, !sources.isEmpty, !actions.isEmpty else { return false }
        guard sources.allSatisfy(\.isValid), actions.allSatisfy(\.isValid) else { return false }
        return logic.isValid(sourceCount: sources.count)
    }

    var payload: ScenarioPayload {
        ScenarioPayload(
            name: name.trimmed,
            description: description.isBlank ? nil : description.trimmed,
            trigger: ScenarioTrigger(
                sources: sources.map(\.triggerSource),
                logic: logic.expression(sourceCount: sources.count)
            ),
            actions: actions.map(\.action),
            active: active,
            group: group.isBlank ? nil : ScenarioGroup(group.trimmed)
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
        group = scenario.displayGroup.isGeneral ? "" : scenario.displayGroup.rawValue
        active = scenario.active
        self.sources = sources
        actions = scenario.actions.map { ScenarioActionDraft(action: $0) }
        logicMode = logic.mode
        customLogic = logic.customExpression ?? ""
    }
}
