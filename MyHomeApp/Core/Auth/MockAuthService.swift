import Foundation

struct MockAuthService: AuthService {
    private static let validEmail = "test@example.com"
    private static let validPassword = "password"

    private let operationDelay: Duration

    init(operationDelay: Duration = .seconds(1)) {
        self.operationDelay = operationDelay
    }

    func login(email: String, password: String) async throws -> AuthToken {
        try await Task.sleep(for: operationDelay)
        guard email == Self.validEmail, password == Self.validPassword else {
            throw AuthError.invalidLoginCredentials
        }
        return AuthToken(
            externalId: "mock-external-id",
            accessToken: "xxx",
            refreshToken: "mock-refresh-token"
        )
    }

    func loginRefresh(refreshToken: String) async throws -> AuthToken {
        try await Task.sleep(for: operationDelay)
        return AuthToken(
            externalId: "mock-external-id",
            accessToken: "refreshed-access-token",
            refreshToken: "mock-refresh-token"
        )
    }

    func register(email _: String, password _: String) async throws {
        try await Task.sleep(for: operationDelay)
    }
}
