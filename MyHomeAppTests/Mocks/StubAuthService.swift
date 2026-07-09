import Foundation
@testable import MyHomeApp

final class StubAuthService: AuthService, @unchecked Sendable {
    var loginResult: Result<AuthToken, Error> = .success(.fixture())
    var refreshResult: Result<AuthToken, Error> = .success(.fixture())
    var registerResult: Result<Void, Error> = .success(())

    private(set) var loginCalls: [(email: String, password: String)] = []
    private(set) var refreshCalls: [String] = []
    private(set) var registerCalls: [(email: String, password: String)] = []

    func login(email: String, password: String) async throws -> AuthToken {
        loginCalls.append((email, password))
        return try loginResult.get()
    }

    func loginRefresh(refreshToken: String) async throws -> AuthToken {
        refreshCalls.append(refreshToken)
        return try refreshResult.get()
    }

    func register(email: String, password: String) async throws {
        registerCalls.append((email, password))
        try registerResult.get()
    }
}
