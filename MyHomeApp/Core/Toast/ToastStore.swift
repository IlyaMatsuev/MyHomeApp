import Foundation
import Observation

@Observable
@MainActor
final class ToastStore {
    private(set) var current: Toast?

    func error(_ message: String) {
        current = Toast(message: message, kind: .error)
    }

    func success(_ message: String) {
        current = Toast(message: message, kind: .success)
    }

    func dismiss() {
        current = nil
    }
}
