protocol MediaSettingsPersistence: Sendable {
    func load() throws -> MediaSettings?
    func save(_ settings: MediaSettings) throws
    func clear() throws
}
