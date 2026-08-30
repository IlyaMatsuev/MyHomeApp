/// A command match some scenario already uses, offered as the default when a new device trigger
/// matches a command — the app has no other source of a device's command names and values.
struct ScenarioKnownCommand: Hashable {
    let deviceId: String
    let name: String
    let value: String
}
