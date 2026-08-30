import Foundation

struct Scenario: Codable, Identifiable, Hashable {
    let externalId: String
    let name: String
    let description: String?

    let trigger: ScenarioTrigger
    let actions: [ScenarioAction]

    /// Mutable so the list can flip it optimistically before the hub confirms.
    var active: Bool

    /// `nil` when the scenario belongs to no group — the hub has no "none" group.
    let group: String?

    /// Executions left before the hub deactivates the scenario; `nil` repeats forever.
    let repeatTimes: Int?

    let createdAt: Date
    let updatedAt: Date

    var id: String { externalId }

    init(
        externalId: String,
        name: String,
        description: String? = nil,
        trigger: ScenarioTrigger,
        actions: [ScenarioAction],
        active: Bool,
        group: String? = nil,
        repeatTimes: Int? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.externalId = externalId
        self.name = name
        self.description = description
        self.trigger = trigger
        self.actions = actions
        self.active = active
        self.group = group
        self.repeatTimes = repeatTimes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Scenario: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}
