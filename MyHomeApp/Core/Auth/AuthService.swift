import Foundation

protocol AuthService: Sendable {
    func login(email: String, password: String) async throws -> AuthToken
    func loginRefresh(refreshToken: String) async throws -> AuthToken
    func register(email: String, password: String) async throws
}
