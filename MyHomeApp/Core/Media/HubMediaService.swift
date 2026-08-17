import Foundation
import os

/// Talks to the MyHomeMediaManager. It authorizes with the same hub access token, so requests go
/// through the shared API client — only the target address differs from the hub one.
struct HubMediaService: MediaService {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "HubMediaService")
    private static let pageSize = 20

    private let client: MyHomeAPIClient
    private let serverProvider: @MainActor @Sendable () -> Server?

    init(client: MyHomeAPIClient, serverProvider: @escaping @MainActor @Sendable () -> Server?) {
        self.client = client
        self.serverProvider = serverProvider
    }

    func isHealthy(server: Server) async -> Bool {
        do {
            try await client.send(.get("/health"), to: server)
            return true
        } catch {
            Self.logger.error("Health check for \"\(server.fullURL)\" failed: \(error.localizedDescription)")
            return false
        }
    }

    func search(term: String, kind: MediaKindFilter, page: Int) async throws -> Page<MediaItem> {
        try await send(.get("/media/search", makeQuery(for: kind, page: page, extra: ["term": term])))
    }

    func fetchLibrary(kind: MediaKindFilter, page: Int) async throws -> Page<MediaItem> {
        try await send(.get("/media/library", makeQuery(for: kind, page: page)))
    }

    func fetchDetails(mediaExternalId: String) async throws -> MediaDetails {
        try await send(.get("/media/library/\(mediaExternalId)"))
    }

    func download(mediaExternalId: String) async throws {
        let request = HubRequest(
            method: .post,
            path: "/media/library/\(mediaExternalId)",
            query: [:],
            body: nil,
            protected: true
        )
        try await send(request)
    }

    func remove(mediaExternalId: String) async throws {
        try await send(.delete("/media/library/\(mediaExternalId)"))
    }

    private func makeQuery(for kind: MediaKindFilter, page: Int, extra: [String: String] = [:]) -> [String: String] {
        var query = extra
        query["page"] = String(page)
        query["pageSize"] = String(Self.pageSize)
        if let type = kind.queryValue {
            query["type"] = type
        }
        return query
    }

    private func send<T: Decodable & Sendable>(_ request: HubRequest) async throws -> T {
        let server = try await resolveServer()
        return try await client.send(request, to: server)
    }

    private func send(_ request: HubRequest) async throws {
        let server = try await resolveServer()
        try await client.send(request, to: server)
    }

    private func resolveServer() async throws -> Server {
        guard let server = await serverProvider(), server.baseURL != nil else {
            throw MediaError.notConfigured
        }
        return server
    }
}
