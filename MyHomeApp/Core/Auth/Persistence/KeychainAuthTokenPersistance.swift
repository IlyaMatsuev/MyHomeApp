import Foundation

final class KeychainAuthTokenPersistance: AuthTokenPersistence {
    private let keychain: KeychainItem

    init(service: String = "com.myhome", account: String = "auth") {
        keychain = KeychainItem(service: service, account: account)
    }

    func load() throws -> AuthToken? {
        guard let data = try keychain.read() else {
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

        try keychain.write(data)
    }

    func clear() throws {
        try keychain.delete()
    }
}
