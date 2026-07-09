import Foundation
import Testing
@testable import MyHomeApp

// swiftlint:disable file_length

@Suite(.serialized)
// swiftlint:disable:next type_body_length
struct HubAPIClientTests {
    private struct SamplePayload: Codable, Equatable {
        let name: String
    }

    private static let server = Server(.http, "hub.local:8080", label: "Test Hub")
    private static let token = AuthToken.fixture(accessToken: "test-token")

    private static func makeClient(
        server: Server? = HubAPIClientTests.server,
        token: AuthToken? = HubAPIClientTests.token,
        handler: @escaping TestURLProtocol.Handler
    ) -> HubAPIClient {
        let client = HubAPIClient(session: .testSession(handler: handler))
        client.setServerProvider { server }
        client.setTokenProvider { token }
        return client
    }

    private static func okResponse(for request: URLRequest, body: Data = Data()) -> (HTTPURLResponse, Data) {
        let url = request.url ?? URL(fileURLWithPath: "/")
        // swiftlint:disable:next force_unwrapping
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        return (response, body)
    }

    private static func response(
        for request: URLRequest,
        status: Int,
        body: Data = Data()
    ) -> (HTTPURLResponse, Data) {
        let url = request.url ?? URL(fileURLWithPath: "/")
        // swiftlint:disable:next force_unwrapping
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
        return (response, body)
    }

    // MARK: - server lookup

    @Test
    func sendThrowsNoServerSelectedWhenServerProviderReturnsNil() async {
        let client = Self.makeClient(server: nil) { _ in (HTTPURLResponse(), Data()) }

        await #expect(throws: HubAPIError.noServerSelected) {
            let _: SamplePayload = try await client.send(.get("/devices"))
        }
    }

    // MARK: - request shape

    @Test
    func sendBuildsURLFromServerBaseAndRequestURI() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices/42"))

        let request = try #require(captured.value)
        #expect(request.url?.absoluteString == "http://hub.local:8080/devices/42")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test
    func sendAttachesQueryItemsFromRequestQueryToURL() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices", ["pageSize": "20"]))

        let request = try #require(captured.value)
        let url = try #require(request.url)
        #expect(url.absoluteString == "http://hub.local:8080/devices?pageSize=20")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/devices")
        #expect(components.queryItems == [URLQueryItem(name: "pageSize", value: "20")])
    }

    @Test
    func sendOmitsQueryStringWhenRequestQueryIsEmpty() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices"))

        let request = try #require(captured.value)
        let url = try #require(request.url)
        #expect(url.absoluteString == "http://hub.local:8080/devices")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == nil)
    }

    @Test
    func sendAttachesJSONBodyAndContentTypeOnPost() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let payload = SamplePayload(name: "lamp")
        let _: SamplePayload = try await client.send(try .post("/devices", payload))

        let request = try #require(captured.value)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(request.bodyData)
        let decoded = try JSONDecoder().decode(SamplePayload.self, from: body)
        #expect(decoded == payload)
    }

    @Test
    func sendAttachesBearerTokenOnProtectedRequest() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices"))

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
    }

    @Test
    func sendOmitsBearerTokenOnUnprotectedRequest() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/health", protected: false))

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func sendOmitsBearerTokenWhenNoTokenAvailable() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient(token: nil) { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices"))

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    // MARK: - decoding

    @Test
    func sendReturnsDecodedResponseBody() async throws {
        let expected = SamplePayload(name: "kitchen")
        let client = Self.makeClient { request in
            Self.okResponse(for: request, body: try Self.encode(expected))
        }

        let result: SamplePayload = try await client.send(.get("/rooms/kitchen"))

        #expect(result == expected)
    }

    @Test
    func sendThrowsDecodingOnMalformedJSON() async {
        let client = Self.makeClient { request in
            Self.okResponse(for: request, body: Data("not-json".utf8))
        }

        await #expect(throws: HubAPIError.self) {
            let _: SamplePayload = try await client.send(.get("/devices"))
        }
    }

    @Test
    func voidSendIgnoresEmptyResponseBody() async throws {
        let client = Self.makeClient { request in
            (Self.response(for: request, status: 204).0, Data())
        }

        try await client.send(.delete("/devices/42"))
    }

    // MARK: - status code mapping

    @Test
    func send401ThrowsUnauthorized() async {
        let client = Self.makeClient { request in
            Self.response(for: request, status: 401)
        }

        await #expect(throws: HubAPIError.unauthorized) {
            let _: SamplePayload = try await client.send(.get("/devices"))
        }
    }

    @Test
    func sendNon2xxThrowsUnexpected() async throws {
        let client = Self.makeClient { request in
            Self.response(for: request, status: 500, body: Data("boom".utf8))
        }

        do {
            let _: SamplePayload = try await client.send(.get("/devices"))
            Issue.record("expected throw")
        } catch let error as HubAPIError {
            #expect(error == .unexpected)
        }
    }

    // MARK: - send(to:)

    @Test
    func sendToServerUsesProvidedServerInsteadOfCurrentServerProvider() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient(server: nil) { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }
        let target = Server(.https, "other.host:9000", label: "Other")

        let _: SamplePayload = try await client.send(.get("/devices"), to: target)

        let request = try #require(captured.value)
        #expect(request.url?.absoluteString == "https://other.host:9000/devices")
    }

    @Test
    func sendToServerAttachesBearerTokenWhenRequestIsProtected() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient(server: nil) { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices"), to: Self.server)

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
    }

    // MARK: - setServerProvider

    @Test
    func sendThrowsNoServerSelectedBeforeServerProviderIsSet() async {
        let client = HubAPIClient(session: .testSession(handler: { _ in (HTTPURLResponse(), Data()) }))

        await #expect(throws: HubAPIError.noServerSelected) {
            let _: SamplePayload = try await client.send(.get("/devices"))
        }
    }

    @Test
    func setServerProviderReplacesServerUsedForSubsequentRequests() async throws {
        let captured = CapturedRequest()
        let client = HubAPIClient(session: .testSession(handler: { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }))

        client.setServerProvider { Server(.http, "first.host:8080", label: "First") }
        let _: SamplePayload = try await client.send(.get("/devices"))
        #expect(try #require(captured.value).url?.absoluteString == "http://first.host:8080/devices")

        client.setServerProvider { Server(.https, "second.host:9000", label: "Second") }
        let _: SamplePayload = try await client.send(.get("/devices"))
        #expect(try #require(captured.value).url?.absoluteString == "https://second.host:9000/devices")
    }

    // MARK: - setTokenProvider

    @Test
    func setTokenProviderReplacesTokenUsedForSubsequentRequests() async throws {
        let captured = CapturedRequest()
        let client = HubAPIClient(session: .testSession(handler: { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }))
        client.setServerProvider { Self.server }

        let _: SamplePayload = try await client.send(.get("/devices"))
        #expect(try #require(captured.value).value(forHTTPHeaderField: "Authorization") == nil)

        client.setTokenProvider { AuthToken.fixture(accessToken: "later-token") }
        let _: SamplePayload = try await client.send(.get("/devices"))
        #expect(try #require(captured.value).value(forHTTPHeaderField: "Authorization") == "Bearer later-token")
    }

    // MARK: - setRefreshHandler — 401 retry

    @Test
    func protected401TriggersRefreshHandlerThenRetriesRequestOnce() async throws {
        let calls = RequestCounter()
        let client = HubAPIClient(session: .testSession(handler: { request in
            calls.append(request)
            if calls.count == 1 {
                return Self.response(for: request, status: 401)
            }
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "ok")))
        }))
        client.setServerProvider { Self.server }
        client.setTokenProvider { Self.token }
        client.setRefreshHandler { true }

        let result: SamplePayload = try await client.send(.get("/devices"))

        #expect(result == SamplePayload(name: "ok"))
        #expect(calls.count == 2)
    }

    @Test
    func protected401SurfacesUnauthorizedWhenRefreshHandlerReturnsFalse() async throws {
        let calls = RequestCounter()
        let client = HubAPIClient(session: .testSession(handler: { request in
            calls.append(request)
            return Self.response(for: request, status: 401)
        }))
        client.setServerProvider { Self.server }
        client.setTokenProvider { Self.token }
        client.setRefreshHandler { false }

        await #expect(throws: HubAPIError.unauthorized) {
            let _: SamplePayload = try await client.send(.get("/devices"))
        }
        #expect(calls.count == 1)
    }

    @Test
    func unprotected401DoesNotTriggerRefreshHandler() async {
        let handlerCalled = ActorFlag()
        let client = HubAPIClient(session: .testSession(handler: { request in
            Self.response(for: request, status: 401)
        }))
        client.setServerProvider { Self.server }
        client.setTokenProvider { Self.token }
        client.setRefreshHandler {
            handlerCalled.set()
            return true
        }

        await #expect(throws: HubAPIError.unauthorized) {
            let _: SamplePayload = try await client.send(.get("/auth/login", protected: false))
        }
        #expect(!handlerCalled.value)
    }

    @Test
    func retryAfterRefreshUsesNewBearerToken() async throws {
        let captured = CapturedRequest()
        let calls = RequestCounter()
        let provider = TokenSwitcher(initial: AuthToken.fixture(accessToken: "old"))
        let client = HubAPIClient(session: .testSession(handler: { request in
            calls.append(request)
            captured.value = request
            if calls.count == 1 {
                return Self.response(for: request, status: 401)
            }
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "ok")))
        }))
        client.setServerProvider { Self.server }
        client.setTokenProvider { provider.current }
        client.setRefreshHandler {
            provider.set(AuthToken.fixture(accessToken: "new"))
            return true
        }

        let _: SamplePayload = try await client.send(.get("/devices"))

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer new")
    }

    // MARK: - transport errors

    @Test
    func sendWrapsURLSessionFailureInTransport() async {
        let client = Self.makeClient { _ in
            throw URLError(.notConnectedToInternet)
        }

        await #expect(throws: HubAPIError.transport) {
            let _: SamplePayload = try await client.send(.get("/devices"))
        }
    }

    // MARK: - helpers

    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }
}

private final class CapturedRequest: @unchecked Sendable {
    var value: URLRequest?
}

private final class RequestCounter: @unchecked Sendable {
    private(set) var count: Int = 0
    func append(_ request: URLRequest) { count += 1 }
}

private final class ActorFlag: @unchecked Sendable {
    private(set) var value: Bool = false
    func set() { value = true }
}

private final class TokenSwitcher: @unchecked Sendable {
    private var token: AuthToken
    init(initial: AuthToken) { token = initial }
    var current: AuthToken? { token }
    func set(_ next: AuthToken) { token = next }
}

private extension URLRequest {
    /// `URLProtocol` receives the request before `httpBody` is set on the wrapper but exposes the
    /// body via `httpBodyStream`. Drain it so tests can decode the payload that actually went out.
    var bodyData: Data? {
        if let body = httpBody { return body }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
