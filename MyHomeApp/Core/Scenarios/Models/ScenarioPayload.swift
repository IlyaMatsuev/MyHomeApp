/// The writable subset of a `Scenario`. `externalId`, `repeatTimes` and the timestamps are owned by the hub.
///
/// The hub merges an update field by field (`dto.name ?? stored.name`), so an omitted key keeps its
/// stored value — which also means a `nil` here cannot clear a description or a group once set.
struct ScenarioPayload: Encodable, Hashable {
    let name: String
    let description: String?
    let group: String?
    let active: Bool
    let trigger: ScenarioTrigger
    let actions: [ScenarioAction]
}
