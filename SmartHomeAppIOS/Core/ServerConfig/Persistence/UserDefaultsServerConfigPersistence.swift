import Foundation

final class UserDefaultsServerConfigPersistence: ServerConfigPersistence, @unchecked Sendable {
    private let key: String
    private let defaults: UserDefaults

    init(key: String = "com.smarthome.servers", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() throws -> [Server]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode([Server].self, from: data)
        } catch {
            throw ServerConfigError.decoding(error)
        }
    }

    func save(_ servers: [Server]) throws {
        guard !servers.isEmpty else { return }

        let data: Data
        do {
            data = try JSONEncoder().encode(servers)
        } catch {
            throw ServerConfigError.encoding(error)
        }
        defaults.set(data, forKey: key)
    }

    func clear() throws {
        defaults.removeObject(forKey: key)
    }
}
