import Foundation

enum AuthTokenPersistanceError: LocalizedError {
    case keychain(status: OSStatus)
    case encoding(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .keychain(let status): "Keychain error: (\(status))."
        case .encoding(let error): "Failed to encode: \(error.localizedDescription)."
        case .decoding(let error): "Failed to decode: \(error.localizedDescription)."
        }
    }
}
