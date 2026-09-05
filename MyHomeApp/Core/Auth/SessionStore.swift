import Foundation
import Observation
import os

@Observable
@MainActor
final class SessionStore {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "SessionStore")

    enum State: Equatable {
        case loading
        case unauthenticated
        case authenticated(AuthSession)
    }

    private(set) var state: State = .loading

    private let service: AuthService
    private let tokenPersistence: AuthTokenPersistence

    var session: AuthSession? {
        if case .authenticated(let session) = state {
            return session
        }
        return nil
    }

    var sessionToken: AuthToken? {
        session?.token
    }

    init(service: AuthService, tokenPersistence: AuthTokenPersistence) {
        self.service = service
        self.tokenPersistence = tokenPersistence
    }

    func load() async {
        do {
            if let token = try tokenPersistence.load() {
                state = .authenticated(AuthSession(token: token))
            } else {
                state = .unauthenticated
            }
        } catch {
            Self.logger.error("Error while loading a session store: \(error.localizedDescription)")
            state = .unauthenticated
        }
    }

    func login(email: String, password: String) async throws {
        let token = try await service.login(email: email, password: password)
        try tokenPersistence.save(token)
        state = .authenticated(AuthSession(token: token))
    }

    func register(email: String, password: String) async throws {
        try await service.register(email: email, password: password)
    }

    func logout() {
        do {
            try tokenPersistence.clear()
        } catch {
            Self.logger.error("Failed to clear the session during logout: \(error.localizedDescription)")
        }
        state = .unauthenticated
    }

    func refresh() async -> Bool {
        do {
            guard let token = sessionToken else {
                throw AuthError.sessionExpired
            }
            let newToken = try await service.loginRefresh(refreshToken: token.refreshToken)
            try tokenPersistence.save(newToken)
            state = .authenticated(AuthSession(token: newToken))
            return true
        } catch AuthError.sessionExpired {
            Self.logger.error("Token refresh failed: session expired")
            try? tokenPersistence.clear()
            state = .unauthenticated
            return false
        } catch {
            Self.logger.error("Token refresh failed, preserving session: \(error.localizedDescription)")
            return false
        }
    }
}
