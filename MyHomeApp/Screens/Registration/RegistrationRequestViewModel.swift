import Foundation
import Observation

@Observable
@MainActor
final class RegistrationRequestViewModel {
    private let registrationStore: RegistrationStore

    private(set) var loading = false
    private(set) var errorMessage: String?

    var email: String = "" {
        didSet { errorMessage = nil }
    }
    var comment: String = "" {
        didSet { errorMessage = nil }
    }

    var isEmailValid: Bool {
        email.isValidEmail
    }

    var showEmailError: Bool {
        !email.isEmpty && !isEmailValid
    }

    var canSubmit: Bool {
        !loading && isEmailValid
    }

    init(registrationStore: RegistrationStore, email: String = "", comment: String = "") {
        self.registrationStore = registrationStore
        self.email = email
        self.comment = comment
    }

    @discardableResult
    func submit() async -> Bool {
        guard canSubmit else { return false }

        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
            try await registrationStore.requestAccess(
                email: email,
                comment: trimmedComment.isEmpty ? nil : trimmedComment
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
