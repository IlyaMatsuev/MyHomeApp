import Foundation
import Observation
import os

@Observable
@MainActor
final class ServerConfigStore {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "ServerConfigStore")

    enum State: Equatable {
        case loading
        case unconfigured
        case configured([Server])
    }

    private(set) var state: State = .loading
    private(set) var selectedServer: Server?

    private let persistence: ServerConfigPersistence
    private let service: ServerConfigService

    var servers: [Server] {
        if case .configured(let servers) = state {
            return servers
        }
        return []
    }

    init(persistence: ServerConfigPersistence, service: ServerConfigService) {
        self.persistence = persistence
        self.service = service
    }

    func isReachable(_ server: Server) async -> Bool {
        await service.isReachable(server: server)
    }

    func load() async {
        do {
            if let servers = try persistence.load(), !servers.isEmpty {
                state = .configured(servers)
                select(servers.first)
            } else {
                state = .unconfigured
                selectedServer = nil
            }
        } catch {
            Self.logger.error("Failed to load server configs: \(error.localizedDescription)")
            state = .unconfigured
            selectedServer = nil
        }
    }

    func save(_ servers: [Server]) async throws {
        if servers.isEmpty {
            state = .unconfigured
            throw ServerConfigError.emptyList
        } else {
            try persistence.save(servers)
            state = .configured(servers)
            if selectedServer.map({ current in !servers.contains { $0.id == current.id } }) ?? true {
                selectedServer = servers.first
            }
        }
    }

    func clear() async throws {
        try persistence.clear()
        state = .unconfigured
        selectedServer = nil
    }

    func select(_ server: Server?) {
        guard let server, servers.contains(where: { $0.id == server.id }) else { return }
        selectedServer = server
    }
}
