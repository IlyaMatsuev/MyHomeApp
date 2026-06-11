protocol ServerConfigPersistence: Sendable {
    func load() throws -> [Server]?
    func save(_ servers: [Server]) throws
    func clear() throws
}
