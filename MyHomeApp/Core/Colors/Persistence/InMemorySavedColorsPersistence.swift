import Foundation

final class InMemorySavedColorsPersistence: SavedColorsPersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [SavedColor]

    init(initial: [SavedColor] = []) {
        stored = initial
    }

    func load() throws -> [SavedColor] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func save(_ colors: [SavedColor]) throws {
        lock.lock()
        defer { lock.unlock() }
        stored = colors
    }
}
