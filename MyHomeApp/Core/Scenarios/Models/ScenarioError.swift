import Foundation

enum ScenarioError {
    static let generic = "Oops... Something went wrong"

    static func text(for error: Error) -> String {
        guard let apiError = error as? HubAPIError else { return generic }

        switch apiError {
        case .transport, .noServerSelected:
            return "No Internet connection"

        case .unauthorized, .forbidden:
            return "Your session has expired, please log in again"

        case .notFound:
            return "This scenario does not exist anymore. Try refreshing the page"

        case .validation(_, let message):
            return message

        case .conflict:
            return "This scenario conflicts with an existing one"

        case .tooManyRequests:
            return "Too many requests. Try again in a moment"

        case .decoding, .unexpected:
            return generic
        }
    }
}
