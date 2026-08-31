import Foundation

final class UserDefaultsFavoriteColorsPersistence: FavoriteColorsPersistence, @unchecked Sendable {
    private let key: String
    private let defaults: UserDefaults

    init(key: String = "com.myhome.favoriteColors", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() throws -> [FavoriteColor] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([FavoriteColor].self, from: data)
    }

    func save(_ colors: [FavoriteColor]) throws {
        defaults.set(try JSONEncoder().encode(colors), forKey: key)
    }
}
