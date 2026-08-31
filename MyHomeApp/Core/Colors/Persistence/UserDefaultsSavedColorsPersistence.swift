import Foundation

final class UserDefaultsSavedColorsPersistence: SavedColorsPersistence, @unchecked Sendable {
    private let key: String
    private let defaults: UserDefaults

    init(key: String = "com.myhome.savedColors", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() throws -> [SavedColor] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([SavedColor].self, from: data)
    }

    func save(_ colors: [SavedColor]) throws {
        defaults.set(try JSONEncoder().encode(colors), forKey: key)
    }
}
