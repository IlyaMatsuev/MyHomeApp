import Foundation
import Observation
import os

@Observable
@MainActor
final class ServerConfigStore {
    private static let logger = Logger(subsystem: "SmartHomeApp", category: "ServerConfigStore")

    enum State: Equatable {
        case loading
        case unconfigured
        case configured([Server])
    }

    private(set) var state: State = .loading

    private let persistence: ServerConfigPersistence

    var servers: [Server] {
        if case .configured(let servers) = state {
            return servers
        }
        return []
    }

    init(persistence: ServerConfigPersistence) {
        self.persistence = persistence
    }

    func load() async {
        do {
            if let servers = try persistence.load(), !servers.isEmpty {
                state = .configured(servers)
            } else {
                state = .unconfigured
            }
        } catch {
            Self.logger.error("Failed to load server configs: \(error.localizedDescription)")
            state = .unconfigured
        }
    }

    func save(_ servers: [Server]) async throws {
        if servers.isEmpty {
            state = .unconfigured
        } else {
            try persistence.save(servers)
            state = .configured(servers)
        }
    }

    func clear() async throws {
        try persistence.clear()
        state = .unconfigured
    }
}
