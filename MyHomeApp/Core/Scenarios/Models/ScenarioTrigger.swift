struct ScenarioTrigger: Codable, Hashable {
    let sources: [ScenarioTriggerSource]

    let logic: String
}
