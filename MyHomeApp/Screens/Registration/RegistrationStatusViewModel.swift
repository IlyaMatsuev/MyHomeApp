import Foundation
import Observation

@Observable
@MainActor
final class RegistrationStatusViewModel {
    private let registrationStore: RegistrationStore

    private(set) var refreshing = false
    private(set) var errorMessage: String?

    var request: RegistrationRequest? {
        registrationStore.pendingRequest
    }

    init(registrationStore: RegistrationStore) {
        self.registrationStore = registrationStore
    }

    func refresh() async {
        guard !refreshing else { return }

        refreshing = true
        errorMessage = nil
        do {
            try await registrationStore.refreshStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
        refreshing = false
    }

    func backToLogin() {
        registrationStore.clear()
    }
}
