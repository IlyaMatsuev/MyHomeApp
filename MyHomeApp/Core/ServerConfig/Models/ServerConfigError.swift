import Foundation

enum ServerConfigError: LocalizedError, Equatable {
    case encoding(Error)
    case decoding(Error)
    case emptyList

    var errorDescription: String? {
        switch self {
        case .emptyList: "Cannot save an empty list of servers. You must add at least one."
        case .encoding(let error): "Failed to encode: \(error.localizedDescription)."
        case .decoding(let error): "Failed to decode: \(error.localizedDescription)."
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.emptyList, .emptyList),
             (.encoding, .encoding),
             (.decoding, .decoding):
            true

        default: false
        }
    }
}
