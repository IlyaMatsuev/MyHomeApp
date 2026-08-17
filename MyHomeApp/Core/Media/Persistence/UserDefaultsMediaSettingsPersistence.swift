import Foundation

final class UserDefaultsMediaSettingsPersistence: MediaSettingsPersistence, @unchecked Sendable {
    private let key: String
    private let defaults: UserDefaults

    init(key: String = "com.myhome.media.settings", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() throws -> MediaSettings? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(MediaSettings.self, from: data)
        } catch {
            throw MediaError.decoding(error)
        }
    }

    func save(_ settings: MediaSettings) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(settings)
        } catch {
            throw MediaError.encoding(error)
        }
        defaults.set(data, forKey: key)
    }

    func clear() throws {
        defaults.removeObject(forKey: key)
    }
}
