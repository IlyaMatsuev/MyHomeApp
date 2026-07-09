import Foundation
import os

/// Providers are mutated only during app construction (see `MyHomeApp`),
/// then read by request handling — hence `@unchecked Sendable`.
final class HubAPIClient: MyHomeAPIClient, @unchecked Sendable {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "HubAPIClient")

    private let session: URLSession

    private var currentServer: @MainActor @Sendable () -> Server?
    private var currentToken: @MainActor @Sendable () -> AuthToken?
    private var refreshHandler: @MainActor @Sendable () async -> Bool

    init(session: URLSession = .shared) {
        self.session = session
        self.currentServer = { nil }
        self.currentToken = { nil }
        self.refreshHandler = { false }
    }

    func setServerProvider(_ provider: @escaping @MainActor @Sendable () -> Server?) {
        currentServer = provider
    }

    func setTokenProvider(_ provider: @escaping @MainActor @Sendable () -> AuthToken?) {
        currentToken = provider
    }

    func setRefreshHandler(_ handler: @escaping @MainActor @Sendable () async -> Bool) {
        refreshHandler = handler
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
            return try JSONDecoder.hubAPI.decode(T.self, from: data)
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
        do {
            return try await performOnce(request, server: server)
        } catch HubAPIError.unauthorized where request.protected {
            Self.logger.log("Received 401 on protected request - attempting refresh")
            if await refreshHandler() {
                return try await performOnce(request, server: server)
            }
            throw HubAPIError.unauthorized
        }
    }

    private func performOnce(_ request: HubRequest, server: Server) async throws -> Data {
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
        Self.logger.debug("Sending a request on \(request.method.rawValue) \"\(request.path)\"")

        let url = buildURL(baseURL: baseURL, request: request)
        var urlRequest = URLRequest(url: url)
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

    private func buildURL(baseURL: URL, request: HubRequest) -> URL {
        var components = URLComponents(url: baseURL.appending(path: request.path), resolvingAgainstBaseURL: false)!
        if !request.query.isEmpty {
            components.queryItems = request.query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url!
    }

    private func handleResponse(_ data: Data, _ response: HTTPURLResponse) throws -> Data {
        let body = String(data: data, encoding: .utf8) ?? "<binary>"
        Self.logger.debug("Received a response (\(response.statusCode)) with a body: \(body)")

        if response.statusCode >= 200 && response.statusCode < 300 {
            return data
        }

        switch response.statusCode {
        case 400:
            let errorResponse = try decodeValidationResponse(data)
            throw HubAPIError.validation(errorResponse.firstError.path, errorResponse.firstError.message)
        case 401:
            throw HubAPIError.unauthorized
        case 403:
            throw HubAPIError.forbidden
        case 404:
            throw HubAPIError.notFound
        case 409:
            throw HubAPIError.conflict
        case 429:
            throw HubAPIError.tooManyRequests
        default:
            throw HubAPIError.unexpected
        }
    }

    private func decodeValidationResponse(_ data: Data, ) throws -> HubErrorResponse {
        do {
            return try JSONDecoder.hubAPI.decode(HubErrorResponse.self, from: data)
        } catch {
            throw HubAPIError.decoding(error.localizedDescription)
        }
    }
}
