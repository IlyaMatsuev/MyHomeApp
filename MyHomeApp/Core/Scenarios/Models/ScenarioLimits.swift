/// Field constraints the hub enforces on scenarios.
enum ScenarioLimits {
    static let nameLength = 3...80
    static let descriptionLength = 10...255
    static let groupNameLength = 3...40
    static let logicLength = 1...80

    /// The hub refuses a scenario with more than one `cron` trigger source.
    static let maxCronSources = 1
}
