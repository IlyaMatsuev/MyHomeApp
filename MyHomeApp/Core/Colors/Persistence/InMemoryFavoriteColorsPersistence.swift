import Foundation

final class InMemoryFavoriteColorsPersistence: FavoriteColorsPersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [FavoriteColor]

    init(initial: [FavoriteColor] = []) {
        stored = initial
    }

    func load() throws -> [FavoriteColor] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func save(_ colors: [FavoriteColor]) throws {
        lock.lock()
        defer { lock.unlock() }
        stored = colors
    }
}
