import Foundation

final class KeychainAuthTokenPersistance: AuthTokenPersistence {
    private let keychainItem = KeychainItem(account: "auth")

    func load() throws -> AuthToken? {
        guard let data = try keychainItem.read() else {
            return nil
        }

        do {
            return try JSONDecoder().decode(AuthToken.self, from: data)
        } catch {
            throw AuthTokenPersistanceError.decoding(error)
        }
    }

    func save(_ token: AuthToken) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(token)
        } catch {
            throw AuthTokenPersistanceError.encoding(error)
        }

        try keychainItem.write(data)
    }

    func clear() throws {
        try keychainItem.delete()
    }
}
