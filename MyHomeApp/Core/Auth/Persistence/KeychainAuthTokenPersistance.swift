import Foundation
import Security

final class KeychainAuthTokenPersistance: AuthTokenPersistence {
    private let service: String
    private let account: String
    private let keychainQuery: KeychainQuery

    init(service: String = "com.myhome", account: String = "auth") {
        self.service = service
        self.account = account
        keychainQuery = KeychainQuery(service: service, account: account)
    }

    func load() throws -> AuthToken? {
        guard let data = try retrieveKeychainItem() else {
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

        try deleteKeychainItem()
        try addKeychainItem(data)
    }

    func clear() throws {
        try deleteKeychainItem()
    }

    private func retrieveKeychainItem() throws -> Data? {
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQuery.retrieve(), &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            return data
        case errSecItemNotFound: return nil
        default: throw AuthTokenPersistanceError.keychain(status: status)
        }
    }

    private func addKeychainItem(_ data: Data) throws {
        let status = SecItemAdd(keychainQuery.store(data), nil)
        if status != errSecSuccess {
            throw AuthTokenPersistanceError.keychain(status: status)
        }
    }

    private func deleteKeychainItem() throws {
        let status = SecItemDelete(keychainQuery.remove())
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AuthTokenPersistanceError.keychain(status: status)
        }
    }

    struct KeychainQuery {
        private var attributes: [String: Any]

        init(service: String, account: String) {
            attributes = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecUseDataProtectionKeychain as String: true
            ]
        }

        func store(_ data: Any) -> CFDictionary {
            attributes.merging([
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]) { (_, new) in new } as CFDictionary
        }

        func retrieve() -> CFDictionary {
            attributes.merging([
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnData as String: true
            ]) { (_, new) in new } as CFDictionary
        }

        func remove() -> CFDictionary {
            attributes as CFDictionary
        }
    }
}
