import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct RegistrationStoreTests {
    private let service: StubRegistrationService
    private let persistence: StubRegistrationPersistence
    private let store: RegistrationStore

    init() {
        service = StubRegistrationService()
        persistence = StubRegistrationPersistence()
        store = RegistrationStore(service: service, persistence: persistence)
    }

    // MARK: - load()

    @Test
    func loadWithPersistedRequestBecomesPending() async {
        let request = RegistrationRequest(externalId: "r-1", email: "a@b.dev", status: .pending)
        persistence.loadResult = .success(request)

        await store.load()

        #expect(store.state == .pending(request))
        #expect(store.pendingRequest == request)
        #expect(store.hasPendingRequest)
    }

    @Test
    func loadWithNoPersistedRequestBecomesNone() async {
        await store.load()

        #expect(store.state == .absent)
        #expect(store.pendingRequest == nil)
        #expect(!store.hasPendingRequest)
    }

    @Test
    func loadWhenPersistenceThrowsBecomesNone() async {
        persistence.loadResult = .failure(RegistrationError.decoding(HubAPIError.transport))

        await store.load()

        #expect(store.state == .absent)
    }

    // MARK: - requestAccess()

    @Test
    func requestAccessOnSuccessPersistsAndBecomesPending() async throws {
        let request = RegistrationRequest(externalId: "r-9", email: "new@home.dev", status: .pending)
        service.requestAccessResult = .success(request)

        try await store.requestAccess(email: "new@home.dev")

        #expect(service.requestedEmails == ["new@home.dev"])
        #expect(persistence.savedRequests == [request])
        #expect(store.state == .pending(request))
    }

    @Test
    func requestAccessOnFailureThrowsAndDoesNotPersist() async {
        await store.load()
        service.requestAccessResult = .failure(RegistrationError.alreadyRequested)

        await #expect(throws: RegistrationError.alreadyRequested) {
            try await store.requestAccess(email: "x@y.dev")
        }

        #expect(store.state == .absent)
        #expect(persistence.savedRequests.isEmpty)
    }

    // MARK: - refreshStatus()

    @Test
    func refreshStatusUpdatesStatusAndPersists() async throws {
        let request = RegistrationRequest(externalId: "r-1", email: "a@b.dev", status: .pending)
        persistence.loadResult = .success(request)
        await store.load()
        service.checkStatusResult = .success(.approved)

        let status = try await store.refreshStatus()

        #expect(status == .approved)
        #expect(service.checkedRequestIds == ["r-1"])
        #expect(store.pendingRequest == request.withStatus(.approved))
        #expect(persistence.savedRequests.last == request.withStatus(.approved))
    }

    @Test
    func refreshStatusWithoutPendingRequestThrows() async {
        await store.load()

        await #expect(throws: RegistrationError.requestNotFound) {
            _ = try await store.refreshStatus()
        }
        #expect(service.checkStatusCallCount == 0)
    }

    @Test
    func refreshStatusOnFailurePropagatesAndKeepsRequest() async {
        let request = RegistrationRequest(externalId: "r-1", email: "a@b.dev", status: .pending)
        persistence.loadResult = .success(request)
        await store.load()
        service.checkStatusResult = .failure(RegistrationError.unexpected)

        await #expect(throws: RegistrationError.unexpected) {
            _ = try await store.refreshStatus()
        }
        #expect(store.pendingRequest == request)
    }

    // MARK: - clear()

    @Test
    func clearRemovesPersistedRequestAndBecomesNone() async {
        let request = RegistrationRequest(externalId: "r-1", email: "a@b.dev", status: .pending)
        persistence.loadResult = .success(request)
        await store.load()

        store.clear()

        #expect(store.state == .absent)
        #expect(persistence.clearCallCount == 1)
        #expect(!store.hasPendingRequest)
    }
}
