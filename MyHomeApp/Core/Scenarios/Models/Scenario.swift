import Foundation

struct Scenario: Codable, Identifiable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case externalId
        case name
        case description
        case trigger
        // The hub calls the action list "devices"; `actions` reads better on this side.
        case actions = "devices"
        case active
        case group
        case createdAt
        case updatedAt
    }

    let externalId: String
    let name: String
    let description: String?

    let trigger: ScenarioTrigger
    let actions: [ScenarioAction]

    /// Mutable so the list can flip it optimistically before the hub confirms.
    var active: Bool
    let group: ScenarioGroup?

    let createdAt: Date
    let updatedAt: Date

    var id: String { externalId }

    /// The group to file this scenario under — the hub may omit it entirely.
    var displayGroup: ScenarioGroup { group ?? .general }

    init(
        externalId: String,
        name: String,
        description: String? = nil,
        trigger: ScenarioTrigger,
        actions: [ScenarioAction],
        active: Bool,
        group: ScenarioGroup? = nil,
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        externalId = try container.decode(String.self, forKey: .externalId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        trigger = try container.decode(ScenarioTrigger.self, forKey: .trigger)
        actions = try container.decodeIfPresent([ScenarioAction].self, forKey: .actions) ?? []
        active = try container.decodeIfPresent(Bool.self, forKey: .active) ?? true
        group = try container.decodeIfPresent(ScenarioGroup.self, forKey: .group)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

extension Scenario: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}
