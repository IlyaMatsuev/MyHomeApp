import Foundation
import Testing
@testable import MyHomeApp

struct HubAuthServiceTests {
    private let client: StubMyHomeAPIClient
    private let service: HubAuthService

    init() {
        client = StubMyHomeAPIClient()
        service = HubAuthService(client: client)
    }

    // MARK: - login()

    @Test
    func loginSendsPutAuthLoginAsUnprotectedRequest() async throws {
        client.response = .data(Self.encodeLoginResponse(
            externalId: "u-1", accessToken: "access", refreshToken: "refresh"
        ))

        _ = try await service.login(email: "user@example.com", password: "password")

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .put)
        #expect(request.path == "/auth/login")
        #expect(request.protected == false)
    }

    @Test
    func loginSendsEmailAndPasswordInRequestBody() async throws {
        client.response = .data(Self.encodeLoginResponse(
            externalId: "u-1", accessToken: "access", refreshToken: "refresh"
        ))

        _ = try await service.login(email: "user@example.com", password: "secret")

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode(LoginRequestPayload.self, from: body)
        #expect(decoded == LoginRequestPayload(email: "user@example.com", password: "secret"))
    }

    @Test
    func loginOnSuccessReturnsAuthTokenFromResponse() async throws {
        client.response = .data(Self.encodeLoginResponse(
            externalId: "ext-1", accessToken: "access-1", refreshToken: "refresh-1"
        ))

        let token = try await service.login(email: "user@example.com", password: "password")

        #expect(token == AuthToken(
            externalId: "ext-1",
            accessToken: "access-1",
            refreshToken: "refresh-1"
        ))
    }

    @Test
    func loginMapsUnauthorizedToInvalidLoginCredentials() async {
        client.response = .error(HubAPIError.unauthorized)

        await #expect(throws: AuthError.invalidLoginCredentials) {
            _ = try await service.login(email: "wrong@example.com", password: "nope")
        }
    }

    @Test
    func loginMapsOtherHubErrorsToUnexpected() async {
        client.response = .error(HubAPIError.transport)

        await #expect(throws: AuthError.unexpected) {
            _ = try await service.login(email: "user@example.com", password: "password")
        }
    }

    @Test
    func loginMapsDecodingErrorToUnexpected() async {
        client.response = .data(Data("not-json".utf8))

        await #expect(throws: AuthError.unexpected) {
            _ = try await service.login(email: "user@example.com", password: "password")
        }
    }

    // MARK: - refresh()

    @Test
    func loginRefreshSendsPutAuthLoginRefreshAsUnprotectedRequest() async throws {
        client.response = .data(Self.encodeLoginResponse(
            externalId: "u-1", accessToken: "new-access", refreshToken: "new-refresh"
        ))

        _ = try await service.loginRefresh(refreshToken: "old-refresh")

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .put)
        #expect(request.path == "/auth/login/refresh")
        #expect(request.protected == false)
    }

    @Test
    func loginRefreshSendsRefreshTokenInRequestBody() async throws {
        client.response = .data(Self.encodeLoginResponse(
            externalId: "u-1", accessToken: "a", refreshToken: "b"
        ))

        _ = try await service.loginRefresh(refreshToken: "the-refresh-token")

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode(RefreshRequestPayload.self, from: body)
        #expect(decoded == RefreshRequestPayload(refreshToken: "the-refresh-token"))
    }

    @Test
    func loginRefreshOnSuccessReturnsAuthTokenFromResponse() async throws {
        client.response = .data(Self.encodeLoginResponse(
            externalId: "ext-2", accessToken: "access-2", refreshToken: "refresh-2"
        ))

        let token = try await service.loginRefresh(refreshToken: "old")

        #expect(token == AuthToken(
            externalId: "ext-2",
            accessToken: "access-2",
            refreshToken: "refresh-2"
        ))
    }

    @Test
    func loginRefreshMapsUnauthorizedToSessionExpired() async {
        client.response = .error(HubAPIError.unauthorized)

        await #expect(throws: AuthError.sessionExpired) {
            _ = try await service.loginRefresh(refreshToken: "old")
        }
    }

    @Test
    func loginRefreshMapsOtherHubErrorsToUnexpected() async {
        client.response = .error(HubAPIError.transport)

        await #expect(throws: AuthError.unexpected) {
            _ = try await service.loginRefresh(refreshToken: "old")
        }
    }

    @Test
    func loginRefreshMapsDecodingErrorToUnexpected() async {
        client.response = .data(Data("not-json".utf8))

        await #expect(throws: AuthError.unexpected) {
            _ = try await service.loginRefresh(refreshToken: "old")
        }
    }

    // MARK: - register()

    @Test
    func registerSendsPostAuthRegisterAsUnprotectedRequest() async throws {
        client.response = .data(Data())

        try await service.register(email: "new@home.dev", password: "secret")

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .post)
        #expect(request.path == "/auth/register")
        #expect(request.protected == false)
    }

    @Test
    func registerSendsEmailAndPasswordInRequestBody() async throws {
        client.response = .data(Data())

        try await service.register(email: "new@home.dev", password: "secret")

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode(LoginRequestPayload.self, from: body)
        #expect(decoded == LoginRequestPayload(email: "new@home.dev", password: "secret"))
    }

    @Test
    func registerMapsConflictToEmailAlreadyRegistered() async {
        client.response = .error(HubAPIError.conflict)

        await #expect(throws: AuthError.emailAlreadyTaken) {
            try await service.register(email: "dup@home.dev", password: "secret")
        }
    }

    @Test
    func registerMapsValidationToRegistrationRejectedWithServerMessage() async {
        let message = "Your registration request has been cancelled. Please submit a new registration request."
        client.response = .error(HubAPIError.validation("email", message))

        await #expect(throws: AuthError.validation(message)) {
            try await service.register(email: "new@home.dev", password: "secret")
        }
    }

    @Test
    func registerMapsOtherHubErrorsToUnexpected() async {
        client.response = .error(HubAPIError.transport)

        await #expect(throws: AuthError.unexpected) {
            try await service.register(email: "new@home.dev", password: "secret")
        }
    }

    // MARK: - helpers

    private struct LoginRequestPayload: Codable, Equatable {
        let email: String
        let password: String
    }

    private struct RefreshRequestPayload: Codable, Equatable {
        let refreshToken: String
    }

    private struct LoginResponsePayload: Encodable {
        let externalId: String
        let accessToken: String
        let refreshToken: String
    }

    private static func encodeLoginResponse(
        externalId: String,
        accessToken: String,
        refreshToken: String
    ) -> Data {
        // swiftlint:disable:next force_try
        try! JSONEncoder().encode(LoginResponsePayload(
            externalId: externalId,
            accessToken: accessToken,
            refreshToken: refreshToken
        ))
    }
}
