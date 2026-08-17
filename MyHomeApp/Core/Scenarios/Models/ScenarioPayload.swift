import Foundation

/// The writable subset of a `Scenario`. Timestamps and `externalId` are owned by the hub.
struct ScenarioPayload: Encodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case trigger
        case actions = "devices"
        case active
        case group
    }

    let name: String
    let description: String?
    let trigger: ScenarioTrigger
    let actions: [ScenarioAction]
    let active: Bool
    let group: ScenarioGroup?
}
