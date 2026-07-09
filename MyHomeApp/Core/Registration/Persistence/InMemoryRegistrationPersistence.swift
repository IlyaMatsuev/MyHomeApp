import Foundation

final class InMemoryRegistrationPersistence: RegistrationPersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: RegistrationRequest?

    init(initial: RegistrationRequest? = nil) {
        stored = initial
    }

    func load() throws -> RegistrationRequest? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func save(_ request: RegistrationRequest) throws {
        lock.lock()
        defer { lock.unlock() }
        stored = request
    }

    func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        stored = nil
    }
}
