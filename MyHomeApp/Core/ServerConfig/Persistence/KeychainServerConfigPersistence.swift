import Foundation
import os

/// Keeps the server list in the Keychain, since a server's custom headers can carry a secret such as a
/// reverse proxy token. A list saved by an older version in `legacy` is moved over on the first load.
struct KeychainServerConfigPersistence: ServerConfigPersistence {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "KeychainServerConfigPersistence")

    private let keychain: KeychainItem
    private let legacy: ServerConfigPersistence

    init(keychain: KeychainItem, legacy: ServerConfigPersistence) {
        self.keychain = keychain
        self.legacy = legacy
    }

    func load() throws -> [Server]? {
        guard let data = try keychain.read() else {
            return try migrateLegacyServers()
        }
        do {
            return try JSONDecoder().decode([Server].self, from: data)
        } catch {
            throw ServerConfigError.decoding(error)
        }
    }

    func save(_ servers: [Server]) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(servers)
        } catch {
            throw ServerConfigError.encoding(error)
        }
        try keychain.write(data)
    }

    func clear() throws {
        try keychain.delete()
        try legacy.clear()
    }

    private func migrateLegacyServers() throws -> [Server]? {
        guard let servers = try legacy.load() else { return nil }
        do {
            try save(servers)
            try legacy.clear()
        } catch {
            // The list is still usable from `legacy`, and the next load retries the move.
            Self.logger.error("Failed to move the servers to the Keychain: \(error.localizedDescription)")
        }
        return servers
    }
}
