import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct RegistrationStatusViewModelTests {
    private let service: StubRegistrationService
    private let store: RegistrationStore
    private let viewModel: RegistrationStatusViewModel

    init() {
        service = StubRegistrationService()
        store = RegistrationStore(service: service, persistence: InMemoryRegistrationPersistence())
        viewModel = RegistrationStatusViewModel(registrationStore: store)
    }

    private func seedPendingRequest(_ request: RegistrationRequest) async {
        service.requestAccessResult = .success(request)
        try? await store.requestAccess(email: request.email, comment: nil)
    }

    // MARK: - request

    @Test
    func requestReflectsStorePendingRequest() async {
        let request = RegistrationRequest.fixture(externalId: "r-1", email: "a@b.dev", status: .pending)
        await seedPendingRequest(request)

        #expect(viewModel.request == request)
    }

    // MARK: - refresh()

    @Test
    func refreshUpdatesStatusFromService() async throws {
        let request = RegistrationRequest.fixture(externalId: "r-1", email: "a@b.dev", status: .pending)
        await seedPendingRequest(request)
        service.refreshRequestResult = .success(.fixture(externalId: "r-1", email: "a@b.dev", status: .approved))

        await viewModel.refresh()

        #expect(service.refreshRequestCallCount == 1)
        #expect(service.refreshedRequestIds == ["r-1"])
        let updated = try #require(viewModel.request)
        #expect(updated.status == .approved)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func refreshWhenServiceFailsSetsErrorMessage() async {
        let request = RegistrationRequest.fixture(externalId: "r-1", email: "a@b.dev", status: .pending)
        await seedPendingRequest(request)
        service.refreshRequestResult = .failure(RegistrationError.unexpected)

        await viewModel.refresh()

        #expect(viewModel.errorMessage == RegistrationError.unexpected.errorDescription)
    }

    // MARK: - cancel()

    @Test
    func cancelClearsPendingRequest() async {
        let request = RegistrationRequest.fixture(externalId: "r-1", email: "a@b.dev", status: .pending)
        await seedPendingRequest(request)

        await viewModel.cancel()

        #expect(!store.hasPendingRequest)
        #expect(viewModel.request == nil)
        #expect(!viewModel.cancelling)
        #expect(service.cancelledRequestIds == [request.externalId])
    }
}
