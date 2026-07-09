import Foundation

enum RegistrationError: LocalizedError, Equatable {
    case alreadyRequested
    case requestNotFound
    case blocked
    case encoding(Error)
    case decoding(Error)
    case unexpected

    var errorDescription: String? {
        switch self {
        case .alreadyRequested: "An access request for this email already exists"
        case .requestNotFound: "This access request no longer exists"
        case .blocked: "This email has been blocked from making requests"
        case .encoding(let error): "Failed to encode: \(error.localizedDescription)"
        case .decoding(let error): "Failed to decode: \(error.localizedDescription)"
        case .unexpected: "Something went wrong. Please try again later"
        }
    }

    static func == (lhs: RegistrationError, rhs: RegistrationError) -> Bool {
        switch (lhs, rhs) {
        case (.alreadyRequested, .alreadyRequested),
             (.requestNotFound, .requestNotFound),
             (.blocked, .blocked),
             (.encoding, .encoding),
             (.decoding, .decoding),
             (.unexpected, .unexpected):
            true
        default: false
        }
    }
}
