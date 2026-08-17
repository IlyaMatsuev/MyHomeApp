import Foundation

enum MediaError: LocalizedError, Equatable {
    case notConfigured
    case encoding(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "The Media Manager is not configured. Add its address in Settings."
        case .encoding(let error): "Failed to encode: \(error.localizedDescription)."
        case .decoding(let error): "Failed to decode: \(error.localizedDescription)."
        }
    }

    static func == (lhs: MediaError, rhs: MediaError) -> Bool {
        switch (lhs, rhs) {
        case (.notConfigured, .notConfigured),
             (.encoding, .encoding),
             (.decoding, .decoding):
            true

        default: false
        }
    }
}
