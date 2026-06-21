import Foundation
import os

struct HubServerConfigService: ServerConfigService {
    private struct InfoResponse: Decodable {
        let label: String
        let address: String
        let port: Int
    }

    private static let logger = Logger(subsystem: "SmartHomeApp", category: "HubServerConfigService")

    private let client: HubAPIClient

    init(client: HubAPIClient) {
        self.client = client
    }

    func isReachable(server: Server) async -> Bool {
        do {
            let _: InfoResponse = try await client.send(.get("/info", protected: false), to: server)
            return true
        } catch {
            Self.logger.error("Reachability check for \"\(server.fullURL)\" failed: \(error.localizedDescription)")
            return false
        }
    }
}
