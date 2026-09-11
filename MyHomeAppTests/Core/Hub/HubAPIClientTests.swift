import Foundation
import Testing
@testable import MyHomeApp

// swiftlint:disable file_length

@Suite(.serialized)
@MainActor
// swiftlint:disable:next type_body_length
struct HubAPIClientTests {
    private struct SamplePayload: Codable, Equatable {
        let name: String
    }

    private nonisolated static let server = Server(.http, "hub.local:8080", label: "Test Hub")
    private nonisolated static let token = AuthToken.fixture(accessToken: "test-token")

    private static func makeClient(
        server: Server? = HubAPIClientTests.server,
        token: AuthToken? = HubAPIClientTests.token,
        handler: @escaping TestURLProtocol.Handler
    ) -> HubAPIClient {
        let context = HubAPIContext()
        context.attach(auth: StubAuthProvider(sessionToken: token), servers: StubServerProvider(selectedServer: server))
        return makeClient(context: context, handler: handler)
    }

    private static func makeClient(
        context: HubAPIContext,
        handler: @escaping TestURLProtocol.Handler
    ) -> HubAPIClient {
        HubAPIClient(context: context, session: .testSession(handler: handler))
    }

    private nonisolated static func okResponse(
        for request: URLRequest,
        body: Data = Data()
    ) -> (HTTPURLResponse, Data) {
        let url = request.url ?? URL(fileURLWithPath: "/")
        // swiftlint:disable:next force_unwrapping
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        return (response, body)
    }

    private nonisolated static func response(
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

    // MARK: - request context — attach

    @Test
    func sendThrowsNoServerSelectedBeforeContextIsAttached() async {
        let client = Self.makeClient(context: HubAPIContext()) { _ in (HTTPURLResponse(), Data()) }

        await #expect(throws: HubAPIError.noServerSelected) {
            let _: SamplePayload = try await client.send(.get("/devices"))
        }
    }

    @Test
    func sendToServerOmitsBearerTokenBeforeContextIsAttached() async throws {
        let captured = CapturedRequest()
        let client = Self.makeClient(context: HubAPIContext()) { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices"), to: Self.server)

        let request = try #require(captured.value)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func attachSuppliesServerAndTokenForSubsequentRequests() async throws {
        let captured = CapturedRequest()
        let context = HubAPIContext()
        let client = Self.makeClient(context: context) { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        context.attach(
            auth: StubAuthProvider(sessionToken: Self.token),
            servers: StubServerProvider(selectedServer: Self.server)
        )
        let _: SamplePayload = try await client.send(.get("/devices"))

        let request = try #require(captured.value)
        #expect(request.url?.absoluteString == "http://hub.local:8080/devices")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
    }

    // MARK: - request context — live provider state

    @Test
    func selectedServerChangeIsUsedBySubsequentRequests() async throws {
        let captured = CapturedRequest()
        let servers = StubServerProvider(selectedServer: Server(.http, "first.host:8080", label: "First"))
        let context = HubAPIContext()
        context.attach(auth: StubAuthProvider(), servers: servers)
        let client = Self.makeClient(context: context) { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices"))
        #expect(try #require(captured.value).url?.absoluteString == "http://first.host:8080/devices")

        servers.selectedServer = Server(.https, "second.host:9000", label: "Second")
        let _: SamplePayload = try await client.send(.get("/devices"))
        #expect(try #require(captured.value).url?.absoluteString == "https://second.host:9000/devices")
    }

    @Test
    func sessionTokenChangeIsUsedBySubsequentRequests() async throws {
        let captured = CapturedRequest()
        let auth = StubAuthProvider()
        let context = HubAPIContext()
        context.attach(auth: auth, servers: StubServerProvider(selectedServer: Self.server))
        let client = Self.makeClient(context: context) { request in
            captured.value = request
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "x")))
        }

        let _: SamplePayload = try await client.send(.get("/devices"))
        #expect(try #require(captured.value).value(forHTTPHeaderField: "Authorization") == nil)

        auth.sessionToken = AuthToken.fixture(accessToken: "later-token")
        let _: SamplePayload = try await client.send(.get("/devices"))
        #expect(try #require(captured.value).value(forHTTPHeaderField: "Authorization") == "Bearer later-token")
    }

    // MARK: - refresh — 401 retry

    @Test
    func protected401TriggersRefreshThenRetriesRequestOnce() async throws {
        let calls = RequestCounter()
        let auth = StubAuthProvider(sessionToken: Self.token) { true }
        let context = HubAPIContext()
        context.attach(auth: auth, servers: StubServerProvider(selectedServer: Self.server))
        let client = Self.makeClient(context: context) { request in
            calls.append(request)
            if calls.count == 1 {
                return Self.response(for: request, status: 401)
            }
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "ok")))
        }

        let result: SamplePayload = try await client.send(.get("/devices"))

        #expect(result == SamplePayload(name: "ok"))
        #expect(calls.count == 2)
        #expect(auth.refreshCount == 1)
    }

    @Test
    func protected401SurfacesUnauthorizedWhenRefreshReturnsFalse() async throws {
        let calls = RequestCounter()
        let auth = StubAuthProvider(sessionToken: Self.token) { false }
        let context = HubAPIContext()
        context.attach(auth: auth, servers: StubServerProvider(selectedServer: Self.server))
        let client = Self.makeClient(context: context) { request in
            calls.append(request)
            return Self.response(for: request, status: 401)
        }

        await #expect(throws: HubAPIError.unauthorized) {
            let _: SamplePayload = try await client.send(.get("/devices"))
        }
        #expect(calls.count == 1)
        #expect(auth.refreshCount == 1)
    }

    @Test
    func unprotected401DoesNotTriggerRefresh() async {
        let auth = StubAuthProvider(sessionToken: Self.token) { true }
        let context = HubAPIContext()
        context.attach(auth: auth, servers: StubServerProvider(selectedServer: Self.server))
        let client = Self.makeClient(context: context) { request in
            Self.response(for: request, status: 401)
        }

        await #expect(throws: HubAPIError.unauthorized) {
            let _: SamplePayload = try await client.send(.get("/auth/login", protected: false))
        }
        #expect(auth.refreshCount == 0)
    }

    @Test
    func retryAfterRefreshUsesNewBearerToken() async throws {
        let captured = CapturedRequest()
        let calls = RequestCounter()
        let auth = StubAuthProvider(sessionToken: AuthToken.fixture(accessToken: "old"))
        auth.refreshHandler = { [unowned auth] in
            auth.sessionToken = AuthToken.fixture(accessToken: "new")
            return true
        }
        let context = HubAPIContext()
        context.attach(auth: auth, servers: StubServerProvider(selectedServer: Self.server))
        let client = Self.makeClient(context: context) { request in
            calls.append(request)
            captured.value = request
            if calls.count == 1 {
                return Self.response(for: request, status: 401)
            }
            return Self.okResponse(for: request, body: try Self.encode(SamplePayload(name: "ok")))
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

    private nonisolated static func encode<T: Encodable>(_ value: T) throws -> Data {
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
