import Foundation
import Observation

@Observable
@MainActor
final class RegisterViewModel {
    private let sessionStore: SessionStore

    private(set) var loading = false
    private(set) var errorMessage: String?

    var email: String {
        didSet { errorMessage = nil }
    }
    var password: String = "" {
        didSet { errorMessage = nil }
    }
    var confirmPassword: String = "" {
        didSet { errorMessage = nil }
    }

    var isEmailValid: Bool {
        email.isValidEmail
    }

    var showEmailError: Bool {
        !email.isEmpty && !isEmailValid
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }

    var showPasswordMismatch: Bool {
        !confirmPassword.isEmpty && !passwordsMatch
    }

    var canSubmit: Bool {
        !loading && isEmailValid && !password.isEmpty && passwordsMatch
    }

    init(sessionStore: SessionStore, email: String = "") {
        self.sessionStore = sessionStore
        self.email = email
    }

    @discardableResult
    func register() async -> Bool {
        guard canSubmit else { return false }

        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            try await sessionStore.register(email: email, password: password)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
