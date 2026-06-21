import Foundation
import Testing
@testable import SmartHomeAppIOS

@MainActor
struct LoginViewModelTests {
    private let service: StubAuthService
    private let store: SessionStore
    private let viewModel: LoginViewModel

    init() {
        service = StubAuthService()
        store = SessionStore(service: service, tokenStore: StubTokenStore())
        viewModel = LoginViewModel(sessionStore: store)
    }

    // MARK: - canSubmit

    @Test
    func canSubmitIsFalseWhenFieldsAreEmpty() {
        #expect(!viewModel.canSubmit)
    }

    @Test
    func canSubmitIsFalseWhenOnlyEmailIsFilled() {
        viewModel.email = "user@example.com"
        #expect(!viewModel.canSubmit)
    }

    @Test
    func canSubmitIsFalseWhenEmailFormatIsInvalid() {
        viewModel.email = "not-an-email"
        viewModel.password = "password"
        #expect(!viewModel.canSubmit)
    }

    @Test
    func canSubmitIsTrueWhenEmailIsValidAndPasswordFilled() {
        viewModel.email = "user@example.com"
        viewModel.password = "password"
        #expect(viewModel.canSubmit)
    }

    // MARK: - email validation

    @Test
    func showEmailErrorIsFalseWhenEmpty() {
        #expect(!viewModel.showEmailError)
    }

    @Test
    func showEmailErrorIsTrueForInvalidNonEmptyEmail() {
        viewModel.email = "abc"
        #expect(viewModel.showEmailError)
    }

    @Test
    func showEmailErrorIsFalseForValidEmail() {
        viewModel.email = "a@b.com"
        #expect(!viewModel.showEmailError)
    }

    @Test(arguments: ["user@example.com", "a.b-c@sub.domain.io", "x+y@z.co"])
    func isEmailValidAcceptsWellFormedAddresses(email: String) {
        viewModel.email = email
        #expect(viewModel.isEmailValid)
    }

    @Test(arguments: ["plainaddress", "no@tld", "@no-local.com", "spaces in@email.com", "trailing@dot."])
    func isEmailValidRejectsMalformedAddresses(email: String) {
        viewModel.email = email
        #expect(!viewModel.isEmailValid)
    }

    // MARK: - error reset on edit

    @Test
    func editingEmailClearsErrorMessage() async {
        service.loginResult = .failure(AuthError.invalidLoginCredentials)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"
        await viewModel.submit()
        #expect(viewModel.errorMessage != nil)

        viewModel.email = "user2@example.com"

        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func editingPasswordClearsErrorMessage() async {
        service.loginResult = .failure(AuthError.invalidLoginCredentials)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"
        await viewModel.submit()
        #expect(viewModel.errorMessage != nil)

        viewModel.password = "another"

        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - submit()

    @Test
    func submitWithInvalidFieldsDoesNotCallService() async {
        await viewModel.submit()

        #expect(service.loginCalls.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func submitOnSuccessAuthenticatesSessionAndClearsError() async {
        let token = AuthToken.fixture(accessToken: "tok")
        service.loginResult = .success(token)
        viewModel.email = "user@example.com"
        viewModel.password = "password"

        await viewModel.submit()

        #expect(store.state == .authenticated(AuthSession(token: token)))
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.loading)
    }

    @Test
    func submitOnFailureSetsErrorMessageAndKeepsStateUnauthenticated() async {
        await store.load()
        service.loginResult = .failure(AuthError.invalidLoginCredentials)
        viewModel.email = "wrong@example.com"
        viewModel.password = "nope"

        await viewModel.submit()

        #expect(viewModel.errorMessage == AuthError.invalidLoginCredentials.errorDescription)
        #expect(store.state == .unauthenticated)
        #expect(!viewModel.loading)
    }
}
