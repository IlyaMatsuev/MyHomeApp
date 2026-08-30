/// Payload used for creating a new and updating an existing scenario.
struct ScenarioPayload: Encodable, Hashable {
    let name: String
    let description: String?
    let group: String?
    let active: Bool
    let trigger: ScenarioTrigger
    let actions: [ScenarioAction]
}
