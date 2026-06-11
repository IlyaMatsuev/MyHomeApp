import Foundation

enum ServerConfigError: LocalizedError {
    case encoding(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .encoding(let error): "Failed to encode: \(error.localizedDescription)."
        case .decoding(let error): "Failed to decode: \(error.localizedDescription)."
        }
    }
}
