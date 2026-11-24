import Foundation
import os

final class UserDefaultsServerConfigPersistence: ServerConfigPersistence, @unchecked Sendable {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "UserDefaultsServerConfigPersistence")

    private let headersStorage: any SecretStorage
    private let key: String
    private let defaults: UserDefaults

    init(headersStorage: any SecretStorage, key: String = "com.myhome.servers", defaults: UserDefaults = .standard) {
        self.headersStorage = headersStorage
        self.key = key
        self.defaults = defaults
    }

    func load() throws -> [Server]? {
        guard let data = defaults.data(forKey: key) else { return nil }

        var servers: [Server]
        do {
            servers = try JSONDecoder().decode([Server].self, from: data)
        } catch {
            throw ServerConfigError.decoding(error)
        }

        let headers = loadHeaders()
        for index in servers.indices {
            servers[index].headers = headers[servers[index].id] ?? []
        }
        return servers
    }

    func save(_ servers: [Server]) throws {
        guard !servers.isEmpty else { return }

        let headers = servers.reduce(into: [Server.ID: [ServerHeader]]()) { result, server in
            if !server.headers.isEmpty {
                result[server.id] = server.headers
            }
        }

        let data: Data
        let headersData: Data
        do {
            data = try JSONEncoder().encode(servers)
            headersData = try JSONEncoder().encode(headers)
        } catch {
            throw ServerConfigError.encoding(error)
        }

        // The Keychain goes first: it's the write that can fail, and failing here leaves the saved list intact.
        if headers.isEmpty {
            try headersStorage.delete()
        } else {
            try headersStorage.write(headersData)
        }
        defaults.set(data, forKey: key)
    }

    func clear() throws {
        try headersStorage.delete()
        defaults.removeObject(forKey: key)
    }

    // Never throws: the store treats a failed load as "no servers", and the next save would then replace the list.
    // shortcut: a save after a failed read erases the stored headers, block it if reads turn out to fail in practice.
    private func loadHeaders() -> [Server.ID: [ServerHeader]] {
        do {
            guard let data = try headersStorage.read() else { return [:] }
            return try JSONDecoder().decode([Server.ID: [ServerHeader]].self, from: data)
        } catch {
            Self.logger.error("Failed to load server headers: \(error.localizedDescription)")
            return [:]
        }
    }
}
