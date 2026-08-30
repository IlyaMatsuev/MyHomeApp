/// Field constraints the hub enforces on scenarios.
///
/// Mirrored from the hub's `scenarios.constants.ts` so the editor can block a request the hub is
/// guaranteed to reject instead of round-tripping to a validation error.
enum ScenarioLimits {
    static let nameLength = 3...80
    static let descriptionLength = 10...255
    static let groupNameLength = 3...40
    static let logicLength = 1...80

    /// The hub refuses a scenario with more than one `cron` trigger source.
    static let maxCronSources = 1
}
