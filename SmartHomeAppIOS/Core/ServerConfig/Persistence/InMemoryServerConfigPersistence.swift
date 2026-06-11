import Foundation

final class InMemoryServerConfigPersistence: ServerConfigPersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [Server]?

    init(initial: [Server]? = nil) {
        stored = initial
    }

    func load() throws -> [Server]? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func save(_ servers: [Server]) throws {
        lock.lock()
        defer { lock.unlock() }
        stored = servers
    }

    func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        stored = nil
    }
}
