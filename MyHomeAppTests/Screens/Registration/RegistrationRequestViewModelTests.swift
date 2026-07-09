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

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        #expect(service.requestAccessCallCount == 1)
        #expect(service.requestedEmails == ["new@home.dev"])
        #expect(service.requestedComments == [nil])
        #expect(store.hasPendingRequest)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func submitForwardsTrimmedCommentWhenProvided() async {
        viewModel.email = "new@home.dev"
        viewModel.comment = "  Please add me  "

        await viewModel.submit()

        #expect(service.requestedComments == ["Please add me"])
    }

    @Test
    func submitSendsNilCommentWhenBlank() async {
        viewModel.email = "new@home.dev"
        viewModel.comment = "   \n  "

        await viewModel.submit()

        #expect(service.requestedComments == [nil])
    }

    @Test
    func submitWhenStoreFailsSetsErrorMessageAndStaysWithoutRequest() async {
        viewModel.email = "new@home.dev"
        service.requestAccessResult = .failure(RegistrationError.alreadyRequested)

        let succeeded = await viewModel.submit()

        #expect(!succeeded)
        #expect(viewModel.errorMessage == RegistrationError.alreadyRequested.errorDescription)
        #expect(!store.hasPendingRequest)
    }

    @Test
    func submitWithInvalidEmailDoesNotCallService() async {
        viewModel.email = "bad"

        let succeeded = await viewModel.submit()

        #expect(!succeeded)
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
