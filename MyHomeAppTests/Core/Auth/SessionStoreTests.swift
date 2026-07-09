import Foundation
import Testing
@testable import MyHomeApp

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

    // MARK: - register()

    @Test
    func registerDelegatesToServiceWithoutChangingState() async throws {
        await store.load()
        #expect(store.state == .unauthenticated)

        try await store.register(email: "new@home.dev", password: "secret")

        #expect(service.registerCalls.count == 1)
        let call = try #require(service.registerCalls.first)
        #expect(call.email == "new@home.dev")
        #expect(call.password == "secret")
        #expect(store.state == .unauthenticated)
        #expect(tokenStore.savedTokens.isEmpty)
    }

    @Test
    func registerPropagatesServiceError() async {
        service.registerResult = .failure(AuthError.emailAlreadyTaken)

        await #expect(throws: AuthError.emailAlreadyTaken) {
            try await store.register(email: "dup@home.dev", password: "secret")
        }
    }

    // MARK: - refresh()

    @Test
    func refreshWhenUnauthenticatedReturnsFalseAndDoesNotCallService() async {
        await store.load()
        #expect(store.state == .unauthenticated)

        let succeeded = await store.refresh()

        #expect(!succeeded)
        #expect(service.refreshCalls.isEmpty)
        #expect(store.state == .unauthenticated)
    }

    @Test
    func refreshOnSuccessReturnsTrueAndSavesNewToken() async throws {
        let original = AuthToken.fixture(accessToken: "old-access", refreshToken: "old-refresh")
        tokenStore.loadResult = .success(original)
        await store.load()

        let renewed = AuthToken.fixture(accessToken: "new-access", refreshToken: "new-refresh")
        service.refreshResult = .success(renewed)

        let succeeded = await store.refresh()

        #expect(succeeded)
        #expect(service.refreshCalls == ["old-refresh"])
        #expect(tokenStore.savedTokens == [renewed])
        #expect(store.state == .authenticated(AuthSession(token: renewed)))
    }

    @Test
    func refreshOnSessionExpiredReturnsFalseClearsSessionAndBecomesUnauthenticated() async {
        let original = AuthToken.fixture(accessToken: "old", refreshToken: "expired-refresh")
        tokenStore.loadResult = .success(original)
        await store.load()
        service.refreshResult = .failure(AuthError.sessionExpired)

        let succeeded = await store.refresh()

        #expect(!succeeded)
        #expect(store.state == .unauthenticated)
        #expect(tokenStore.clearCallCount == 1)
    }

    @Test
    func refreshOnUnexpectedErrorReturnsFalseAndPreservesSession() async {
        let original = AuthToken.fixture(accessToken: "old", refreshToken: "refresh")
        tokenStore.loadResult = .success(original)
        await store.load()
        service.refreshResult = .failure(AuthError.unexpected)

        let succeeded = await store.refresh()

        #expect(!succeeded)
        #expect(store.state == .authenticated(AuthSession(token: original)))
        #expect(tokenStore.clearCallCount == 0)
    }
}
