struct ScenarioTrigger: Codable, Hashable {
    let sources: [ScenarioTriggerSource]

    /// Positional boolean expression combining the sources, e.g. `"(1 OR 2) AND 3"`. Required by the hub.
    /// Use `ScenarioTriggerLogic` to work with it rather than reading the string directly.
    let logic: String
}
