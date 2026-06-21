import Foundation
import Testing
@testable import SmartHomeAppIOS

struct HubAuthServiceTests {
    private let client: StubHubAPIClient
    private let service: HubAuthService

    init() {
        client = StubHubAPIClient()
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
        #expect(request.uri == "/auth/login")
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

    // MARK: - helpers

    private struct LoginRequestPayload: Codable, Equatable {
        let email: String
        let password: String
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
