protocol SavedColorsPersistence: Sendable {
    func load() throws -> [SavedColor]
    func save(_ colors: [SavedColor]) throws
}
