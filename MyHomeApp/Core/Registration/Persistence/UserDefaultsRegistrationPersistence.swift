import Foundation

final class UserDefaultsRegistrationPersistence: RegistrationPersistence, @unchecked Sendable {
    private let key: String
    private let defaults: UserDefaults

    init(key: String = "com.myhome.registrationRequest", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() throws -> RegistrationRequest? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(RegistrationRequest.self, from: data)
        } catch {
            throw RegistrationError.decoding(error)
        }
    }

    func save(_ request: RegistrationRequest) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(request)
        } catch {
            throw RegistrationError.encoding(error)
        }
        defaults.set(data, forKey: key)
    }

    func clear() throws {
        defaults.removeObject(forKey: key)
    }
}
