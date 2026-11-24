import Foundation

enum ServerConfigError: LocalizedError, Equatable {
    case encoding(Error)
    case decoding(Error)
    case emptyList
    case headersUnreadable

    var errorDescription: String? {
        switch self {
        case .emptyList: "Cannot save an empty list of servers. You must add at least one."
        case .headersUnreadable: "Couldn't read the saved HTTP headers. Restart the app and try again."
        case .encoding(let error): "Failed to encode: \(error.localizedDescription)."
        case .decoding(let error): "Failed to decode: \(error.localizedDescription)."
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.emptyList, .emptyList),
             (.headersUnreadable, .headersUnreadable),
             (.encoding, .encoding),
             (.decoding, .decoding):
            true

        default: false
        }
    }
}
