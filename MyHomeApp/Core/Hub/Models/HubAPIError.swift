import Foundation

enum HubAPIError: LocalizedError, Equatable {
    case noServerSelected
    case transport
    case decoding(String)
    case unauthorized
    case forbidden
    case validation(String, String)
    case notFound
    case conflict
    case tooManyRequests
    case unexpected

    var errorDescription: String? {
        switch self {
        case .noServerSelected:
            "No server is selected. Setup a server first."
        case .transport:
            "Cannot reach the server. Are you connected to the same network?"
        case .decoding(let message):
            "Failed to decode the server response: \(message)"
        case .unauthorized:
            "The request was not authorized."
        case .forbidden:
            "The request was forbidden"
        case .validation(_, let message):
            message
        case .notFound:
            "The requested resource was not found"
        case .conflict:
            "The request conflicts with the current state of the server"
        case .tooManyRequests:
            "You've done too many requests. Try again later."
        case .unexpected:
            "Something went wrong"
        }
    }
}
