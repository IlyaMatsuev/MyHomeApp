import Foundation
import Testing
@testable import SmartHomeAppIOS

@MainActor
struct SessionStoreTests {
    private let service: StubAuthService
    private let tokenStore: StubTokenStore
    private let store: SessionStore

    init() {
        service = StubAuthService()
        tokenStore = StubTokenStore()
        store = SessionStore(service: service, tokenStore: tokenStore)
    }

    // MARK: - init

    @Test
    func initialStateIsLoading() {
        #expect(store.state == .loading)
        #expect(store.session == nil)
    }

    // MARK: - load()

    @Test
    func loadWithPersistedTokenBecomesAuthenticated() async throws {
        let token = AuthToken.fixture(accessToken: "abc")
        tokenStore.loadResult = .success(token)

        await store.load()

        #expect(store.state == .authenticated(AuthSession(token: token)))
        let session = try #require(store.session)
        #expect(session.token == token)
    }

    @Test
    func loadWithNoPersistedTokenBecomesUnauthenticated() async {
        tokenStore.loadResult = .success(nil)

        await store.load()

        #expect(store.state == .unauthenticated)
        #expect(store.session == nil)
    }

    @Test
    func loadWhenTokenStoreThrowsBecomesUnauthenticated() async {
        tokenStore.loadResult = .failure(TokenStoreError.keychain(status: -1))

        await store.load()

        #expect(store.state == .unauthenticated)
        #expect(store.session == nil)
    }

    // MARK: - login()

    @Test
    func loginOnSuccessSavesTokenAndBecomesAuthenticated() async throws {
        let token = AuthToken.fixture(accessToken: "tok")
        service.loginResult = .success(token)

        try await store.login(email: "user@example.com", password: "password")

        #expect(store.state == .authenticated(AuthSession(token: token)))
        #expect(tokenStore.savedTokens == [token])
        #expect(service.loginCalls.count == 1)
        let loginCall = try #require(service.loginCalls.first)
        #expect(loginCall.email == "user@example.com")
        #expect(loginCall.password == "password")
    }

    @Test
    func loginOnFailureThrowsAndLeavesStateUnchanged() async {
        await store.load()
        #expect(store.state == .unauthenticated)
        service.loginResult = .failure(AuthError.invalidLoginCredentials)

        await #expect(throws: AuthError.invalidLoginCredentials) {
            try await store.login(email: "x@y.com", password: "nope")
        }

        #expect(store.state == .unauthenticated)
        #expect(tokenStore.savedTokens.isEmpty)
    }
}
