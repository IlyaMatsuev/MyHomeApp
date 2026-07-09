import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct CreateAccountViewModelTests {
    private let service: StubAuthService
    private let store: SessionStore
    private let viewModel: RegisterViewModel

    init() {
        service = StubAuthService()
        store = SessionStore(service: service, tokenStore: InMemoryTokenStore())
        viewModel = RegisterViewModel(sessionStore: store, email: "new@home.dev")
    }

    // MARK: - init / validation

    @Test
    func initPrefillsEmail() {
        #expect(viewModel.email == "new@home.dev")
    }

    @Test
    func canSubmitWhenEmailValidAndPasswordsMatch() {
        viewModel.password = "secret"
        viewModel.confirmPassword = "secret"

        #expect(viewModel.canSubmit)
        #expect(!viewModel.showPasswordMismatch)
    }

    @Test
    func canSubmitFalseWhenPasswordsMismatch() {
        viewModel.password = "secret"
        viewModel.confirmPassword = "different"

        #expect(!viewModel.canSubmit)
        #expect(viewModel.showPasswordMismatch)
    }

    @Test
    func canSubmitFalseWhenEmailInvalid() {
        viewModel.email = "not-an-email"
        viewModel.password = "secret"
        viewModel.confirmPassword = "secret"

        #expect(!viewModel.canSubmit)
    }

    @Test
    func canSubmitFalseWhenPasswordEmpty() {
        #expect(!viewModel.canSubmit)
    }

    // MARK: - register()

    @Test
    func registerOnSuccessCallsServiceAndReturnsTrue() async {
        viewModel.password = "secret"
        viewModel.confirmPassword = "secret"

        let succeeded = await viewModel.register()

        #expect(succeeded)
        #expect(service.registerCalls.count == 1)
        #expect(service.registerCalls.first?.email == "new@home.dev")
        #expect(service.registerCalls.first?.password == "secret")
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func registerOnFailureSetsErrorMessageAndReturnsFalse() async {
        viewModel.password = "secret"
        viewModel.confirmPassword = "secret"
        service.registerResult = .failure(AuthError.emailAlreadyTaken)

        let succeeded = await viewModel.register()

        #expect(!succeeded)
        #expect(viewModel.errorMessage == AuthError.emailAlreadyTaken.errorDescription)
    }

    @Test
    func registerWhenNotSubmittableDoesNotCallService() async {
        viewModel.password = "secret"
        viewModel.confirmPassword = "different"

        let succeeded = await viewModel.register()

        #expect(!succeeded)
        #expect(service.registerCalls.isEmpty)
    }
}
