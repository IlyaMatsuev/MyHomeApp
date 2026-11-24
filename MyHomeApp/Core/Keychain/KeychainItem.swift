import Foundation
import Security

struct KeychainItem: SecretStorage {
    struct Failure: LocalizedError {
        let status: OSStatus

        var errorDescription: String? {
            "Couldn't access the Keychain (\(status))."
        }
    }

    private static let service = "com.myhome"

    let account: String

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
    }

    func read() throws -> Data? {
        let options: [String: Any] = [
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query.merging(options) { _, new in new } as CFDictionary, &result)

        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw Failure(status: status)
        }
    }

    // Updates in place instead of deleting first, so a failed write can't destroy the previous value.
    func write(_ data: Data) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
        if status != errSecSuccess {
            throw Failure(status: status)
        }
    }

    func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw Failure(status: status)
        }
    }
}
