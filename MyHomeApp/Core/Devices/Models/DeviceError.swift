import Foundation

enum DeviceError {
    static let generic = "Oops... Something went wrong"

    static func text(for error: Error) -> String {
        guard let apiError = error as? HubAPIError else {
            return (error as? LocalizedError)?.errorDescription ?? generic
        }

        switch apiError {
        case .transport, .noServerSelected:
            return "No Internet connection"

        case .unauthorized, .forbidden:
            return "Your session has expired, please log in again"

        case .notFound:
            return "This device does not exist anymore. Try refreshing the page"

        case .validation(_, let message):
            return message

        case .conflict:
            return "A device with these details already exists"

        case .tooManyRequests:
            return "Too many requests. Try again in a moment"

        case .decoding, .unexpected:
            return generic
        }
    }
}
