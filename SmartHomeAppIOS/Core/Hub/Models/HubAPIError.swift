import Foundation

enum HubAPIError: LocalizedError, Equatable {
    case noServerSelected
    case transport
    case decoding(String)
    case unauthorized
    case http(status: Int, body: String?)

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
        case .http(let status, let body):
            "Server returned \(status)\(body.map { ": \($0)" } ?? "")"
        }
    }
}
