import Foundation

/// User-facing wording for the errors the Media Manager screens can run into.
enum MediaErrorMessage {
    static func text(for error: Error) -> String {
        switch error {
        case MediaError.notConfigured:
            return "The Media Manager is not configured. Add its address in Settings."

        case HubAPIError.transport:
            return "Couldn't reach the Media Manager. Are you connected to the same network?"

        case HubAPIError.unauthorized, HubAPIError.forbidden:
            return "Your session has expired, please log in again"

        case HubAPIError.notFound:
            return "This title is not available anymore. Try refreshing the page"

        default:
            return "Oops... Something went wrong"
        }
    }
}
