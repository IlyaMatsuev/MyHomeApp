import Foundation

final class InMemoryMediaSettingsPersistence: MediaSettingsPersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: MediaSettings?

    init(initial: MediaSettings? = nil) {
        stored = initial
    }

    func load() throws -> MediaSettings? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func save(_ settings: MediaSettings) throws {
        lock.lock()
        defer { lock.unlock() }
        stored = settings
    }

    func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        stored = nil
    }
}
