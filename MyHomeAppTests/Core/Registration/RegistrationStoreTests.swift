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

    private func yieldUntil(_ condition: () -> Bool, maxYields: Int = 100) async {
        var count = 0
        while !condition() && count < maxYields {
            await Task.yield()
            count += 1
        }
    }

    // MARK: - load()

    @Test
    func loadWithPersistedRequestBecomesPending() async {
        let request = RegistrationRequest.fixture(externalId: "r-1", email: "a@b.dev", status: .pending)
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
        let request = RegistrationRequest.fixture(externalId: "r-9", email: "new@home.dev", status: .pending)
        service.requestAccessResult = .success(request)

        try await store.requestAccess(email: "new@home.dev", comment: nil)

        #expect(service.requestedEmails == ["new@home.dev"])
        #expect(persistence.savedRequests == [request])
        #expect(store.state == .pending(request))
        #expect(service.cancelRequestCallCount == 0)
    }

    @Test
    func requestAccessOverridesPreviousPendingRequest() async throws {
        let first = RegistrationRequest.fixture(externalId: "r-1", email: "first@home.dev", status: .pending)
        service.requestAccessResult = .success(first)
        try await store.requestAccess(email: "first@home.dev", comment: nil)

        let second = RegistrationRequest.fixture(externalId: "r-2", email: "second@home.dev", status: .pending)
        service.requestAccessResult = .success(second)
        try await store.requestAccess(email: "second@home.dev", comment: nil)

        #expect(store.state == .pending(second))
        #expect(store.pendingRequest == second)
        #expect(persistence.savedRequests == [first, second])

        // The previous request is cancelled in a fire-and-forget task; let it run.
        await yieldUntil { service.cancelledRequestIds == [first.externalId] }
        #expect(service.cancelledRequestIds == [first.externalId])
    }

    @Test
    func requestAccessForSameEmailDoesNotCancelPreviousRequest() async throws {
        let rejected = RegistrationRequest.fixture(externalId: "r-1", email: "same@home.dev", status: .rejected)
        service.requestAccessResult = .success(rejected)
        try await store.requestAccess(email: "same@home.dev", comment: nil)

        let resubmitted = RegistrationRequest.fixture(externalId: "r-2", email: "Same@Home.dev", status: .pending)
        service.requestAccessResult = .success(resubmitted)
        try await store.requestAccess(email: "Same@Home.dev", comment: "again")

        #expect(store.pendingRequest == resubmitted)

        // Give any (unexpected) fire-and-forget cancel a chance to run before asserting none happened.
        await yieldUntil { service.cancelRequestCallCount > 0 }
        #expect(service.cancelledRequestIds.isEmpty)
    }

    @Test
    func requestAccessFailureKeepsPreviousRequestAndDoesNotCancelIt() async throws {
        let existing = RegistrationRequest.fixture(externalId: "r-1", email: "first@home.dev", status: .pending)
        service.requestAccessResult = .success(existing)
        try await store.requestAccess(email: "first@home.dev", comment: nil)

        service.requestAccessResult = .failure(RegistrationError.unexpected)

        await #expect(throws: RegistrationError.unexpected) {
            try await store.requestAccess(email: "second@home.dev", comment: nil)
        }

        #expect(store.state == .pending(existing))
        #expect(store.pendingRequest == existing)
        #expect(service.cancelledRequestIds.isEmpty)
    }

    @Test
    func requestAccessOnFailureThrowsAndDoesNotPersist() async {
        await store.load()
        service.requestAccessResult = .failure(RegistrationError.alreadyRequested)

        await #expect(throws: RegistrationError.alreadyRequested) {
            try await store.requestAccess(email: "x@y.dev", comment: nil)
        }

        #expect(store.state == .absent)
        #expect(persistence.savedRequests.isEmpty)
    }

    // MARK: - refreshStatus()

    @Test
    func refreshStatusUpdatesRequestAndPersists() async throws {
        let pending = RegistrationRequest.fixture(externalId: "r-1", status: .pending)
        persistence.loadResult = .success(pending)
        await store.load()
        let approved = RegistrationRequest.fixture(externalId: "r-1", status: .approved, role: .resident)
        service.refreshRequestResult = .success(approved)

        let refreshed = try await store.refreshStatus()

        #expect(refreshed == approved)
        #expect(service.refreshedRequestIds == ["r-1"])
        #expect(store.pendingRequest == approved)
        #expect(persistence.savedRequests.last == approved)
    }

    @Test
    func refreshStatusWithoutPendingRequestThrows() async {
        await store.load()

        await #expect(throws: RegistrationError.requestNotFound) {
            _ = try await store.refreshStatus()
        }
        #expect(service.refreshRequestCallCount == 0)
    }

    @Test
    func refreshStatusOnFailurePropagatesAndKeepsRequest() async {
        let request = RegistrationRequest.fixture(externalId: "r-1")
        persistence.loadResult = .success(request)
        await store.load()
        service.refreshRequestResult = .failure(RegistrationError.unexpected)

        await #expect(throws: RegistrationError.unexpected) {
            _ = try await store.refreshStatus()
        }
        #expect(store.pendingRequest == request)
    }

    // MARK: - clear()

    @Test
    func clearRemovesPersistedRequestAndBecomesNone() async {
        let request = RegistrationRequest.fixture(externalId: "r-1", email: "a@b.dev", status: .pending)
        persistence.loadResult = .success(request)
        await store.load()

        store.clear()

        #expect(store.state == .absent)
        #expect(persistence.clearCallCount == 1)
        #expect(!store.hasPendingRequest)
    }

    // MARK: - cancelAndClear()

    @Test
    func cancelRemovesPersistedRequestAndBecomesAbsent() async {
        let request = RegistrationRequest.fixture(externalId: "r-1", email: "a@b.dev", status: .pending)
        persistence.loadResult = .success(request)
        await store.load()

        await store.cancelAndClear()

        #expect(store.state == .absent)
        #expect(persistence.clearCallCount == 1)
        #expect(!store.hasPendingRequest)
        #expect(service.cancelledRequestIds == [request.externalId])
    }

    @Test
    func cancelAndClearWithoutPendingRequestDoesNotCallService() async {
        await store.load()

        await store.cancelAndClear()

        #expect(store.state == .absent)
        #expect(persistence.clearCallCount == 1)
        #expect(service.cancelRequestCallCount == 0)
    }
}
