import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    private let sessionStore: SessionStore

    private(set) var loading = false
    private(set) var errorMessage: String?

    var email: String = "" {
        didSet { errorMessage = nil }
    }
    var password: String = "" {
        didSet { errorMessage = nil }
    }

    var isEmailValid: Bool {
        email.isValidEmail
    }

    var isPasswordValid: Bool {
        !password.isEmpty
    }

    var showEmailError: Bool {
        !email.isEmpty && !isEmailValid
    }

    var canSubmit: Bool {
        !loading && isEmailValid && isPasswordValid
    }

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func submit() async {
        guard canSubmit else { return }

        loading = true
        errorMessage = nil
        do {
            try await sessionStore.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}
