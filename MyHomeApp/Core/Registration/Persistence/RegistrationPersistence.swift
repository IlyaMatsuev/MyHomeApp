protocol RegistrationPersistence: Sendable {
    func load() throws -> RegistrationRequest?
    func save(_ request: RegistrationRequest) throws
    func clear() throws
}
