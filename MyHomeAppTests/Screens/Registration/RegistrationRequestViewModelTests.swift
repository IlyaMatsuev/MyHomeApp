import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct RegistrationRequestViewModelTests {
    private let service: StubRegistrationService
    private let store: RegistrationStore
    private let viewModel: RegistrationRequestViewModel

    init() {
        service = StubRegistrationService()
        store = RegistrationStore(service: service, persistence: InMemoryRegistrationPersistence())
        viewModel = RegistrationRequestViewModel(registrationStore: store)
    }

    // MARK: - email validation

    @Test
    func wellFormedEmailIsValidAndSubmittable() {
        viewModel.email = "user@example.com"

        #expect(viewModel.isEmailValid)
        #expect(!viewModel.showEmailError)
        #expect(viewModel.canSubmit)
    }

    @Test
    func malformedEmailIsInvalidAndShowsError() {
        viewModel.email = "not-an-email"

        #expect(!viewModel.isEmailValid)
        #expect(viewModel.showEmailError)
        #expect(!viewModel.canSubmit)
    }

    @Test
    func emptyEmailIsInvalidButHidesError() {
        #expect(!viewModel.isEmailValid)
        #expect(!viewModel.showEmailError)
        #expect(!viewModel.canSubmit)
    }

    // MARK: - submit()

    @Test
    func submitWithValidEmailRequestsAccessThroughStore() async {
        viewModel.email = "new@home.dev"

        await viewModel.submit()

        #expect(service.requestAccessCallCount == 1)
        #expect(service.requestedEmails == ["new@home.dev"])
        #expect(store.hasPendingRequest)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func submitWhenStoreFailsSetsErrorMessageAndStaysWithoutRequest() async {
        viewModel.email = "new@home.dev"
        service.requestAccessResult = .failure(RegistrationError.alreadyRequested)

        await viewModel.submit()

        #expect(viewModel.errorMessage == RegistrationError.alreadyRequested.errorDescription)
        #expect(!store.hasPendingRequest)
    }

    @Test
    func submitWithInvalidEmailDoesNotCallService() async {
        viewModel.email = "bad"

        await viewModel.submit()

        #expect(service.requestAccessCallCount == 0)
    }

    @Test
    func editingEmailClearsPreviousErrorMessage() async {
        viewModel.email = "new@home.dev"
        service.requestAccessResult = .failure(RegistrationError.unexpected)
        await viewModel.submit()
        #expect(viewModel.errorMessage != nil)

        viewModel.email = "another@home.dev"

        #expect(viewModel.errorMessage == nil)
    }
}
