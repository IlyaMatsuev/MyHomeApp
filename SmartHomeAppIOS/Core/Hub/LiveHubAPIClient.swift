import Foundation
import os

/// Token provider is mutated only during app construction (see `SmartHomeAppIOSApp`),
/// then read by request handling — hence `@unchecked Sendable`.
final class LiveHubAPIClient: HubAPIClient, @unchecked Sendable {
    private static let logger = Logger(subsystem: "SmartHomeApp", category: "LiveHubAPIClient")

    private let session: URLSession

    private var currentServer: @MainActor @Sendable () -> Server?
    private var currentToken: @MainActor @Sendable () -> AuthToken?

    init(session: URLSession = .shared) {
        self.session = session
        self.currentServer = { nil }
        self.currentToken = { nil }
    }

    func setServerProvider(_ provider: @escaping @MainActor @Sendable () -> Server?) {
        currentServer = provider
    }

    func setTokenProvider(_ provider: @escaping @MainActor @Sendable () -> AuthToken?) {
        currentToken = provider
    }

    func send<T: Decodable & Sendable>(_ request: HubRequest) async throws -> T {
        let server = try await resolveCurrentServer()
        return try await send(request, to: server)
    }

    func send(_ request: HubRequest) async throws {
        let server = try await resolveCurrentServer()
        try await send(request, to: server)
    }

    func send<T: Decodable & Sendable>(_ request: HubRequest, to server: Server) async throws -> T {
        let data = try await perform(request, server: server)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HubAPIError.decoding(error.localizedDescription)
        }
    }

    func send(_ request: HubRequest, to server: Server) async throws {
        _ = try await perform(request, server: server)
    }

    private func resolveCurrentServer() async throws -> Server {
        guard let server = await currentServer() else {
            throw HubAPIError.noServerSelected
        }
        return server
    }

    private func perform(_ request: HubRequest, server: Server) async throws -> Data {
        guard let baseURL = server.baseURL else {
            throw HubAPIError.noServerSelected
        }

        let urlRequest = await createRequest(baseURL, request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            let reason = error.localizedDescription
            Self.logger.error("Failed to send a request: \(reason)")
            throw HubAPIError.transport
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            Self.logger.error("Failed to send a request: non-HTTP response")
            throw HubAPIError.transport
        }

        return try handleResponse(data, httpResponse)
    }

    private func createRequest(_ baseURL: URL, _ request: HubRequest) async -> URLRequest {
        Self.logger.debug("Sending a request on \(request.method.rawValue) \"\(request.uri)\"")

        var urlRequest = URLRequest(url: baseURL.appending(path: request.uri))
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = request.body {
            Self.logger.debug("  with a body: \(String(data: body, encoding: .utf8) ?? "<binary>")")

            urlRequest.httpBody = body
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if request.protected, let token = await currentToken() {
            urlRequest.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }

    private func handleResponse(_ data: Data, _ response: HTTPURLResponse) throws -> Data {
        let body = String(data: data, encoding: .utf8) ?? "<binary>"
        Self.logger.debug("Received a response (\(response.statusCode)) with a body: \(body)")

        switch response.statusCode {
        case 200..<300:
            return data
        case 401:
            throw HubAPIError.unauthorized
        default:
            throw HubAPIError.http(status: response.statusCode, body: String(data: data, encoding: .utf8))
        }
    }
}
