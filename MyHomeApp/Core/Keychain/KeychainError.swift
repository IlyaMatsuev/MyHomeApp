import Foundation
import Security

struct KeychainError: LocalizedError, Equatable {
    let status: OSStatus

    var errorDescription: String? {
        let reason = SecCopyErrorMessageString(status, nil) as String? ?? "status \(status)"
        return "Keychain error: \(reason)."
    }
}
