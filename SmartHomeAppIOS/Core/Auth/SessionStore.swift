import Foundation
import Observation
import os

@Observable
@MainActor
final class SessionStore {
    private static let logger = Logger(subsystem: "SmartHomeApp", category: "SessionStore")

    enum State: Equatable {
        case loading
        case unauthenticated
        case authenticated(AuthSession)
    }

    private(set) var state: State = .loading

    private let service: AuthService
    private let tokenStore: TokenStore

    var session: AuthSession? {
        if case .authenticated(let session) = state {
            return session
        }
        return nil
    }

    var sessionToken: AuthToken? {
        return session == nil ? nil : session?.token
    }

    init(service: AuthService, tokenStore: TokenStore) {
        self.service = service
        self.tokenStore = tokenStore
    }

    func load() async {
        do {
            if let token = try tokenStore.load() {
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
        try tokenStore.save(token)
        state = .authenticated(AuthSession(token: token))
    }
}
