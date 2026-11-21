import Foundation
import Security

/// A single generic-password Keychain item. It's readable once the device has been unlocked after a restart
/// and never leaves the device, so backups don't carry it.
struct KeychainItem: Sendable {
    private let service: String
    private let account: String

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
    }

    init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    func read() throws -> Data? {
        var retrieveQuery = query
        retrieveQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        retrieveQuery[kSecReturnData as String] = true

        var result: AnyObject?
        let status = SecItemCopyMatching(retrieveQuery as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw KeychainError(status: status)
        }
    }

    /// Updates the item in place, so a failed write leaves the previous value intact.
    func write(_ data: Data) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainError(status: updateStatus)
        }

        let addStatus = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError(status: addStatus)
        }
    }

    func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }
}
