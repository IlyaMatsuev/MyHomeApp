import Foundation

enum AuthError: LocalizedError, Equatable {
    case invalidLoginCredentials
    case sessionExpired
    case emailAlreadyTaken
    case validation(String)
    case unexpected

    var errorDescription: String? {
        switch self {
        case .invalidLoginCredentials: "Invalid email or password."
        case .sessionExpired: "Your session has expired. Please log in again."
        case .emailAlreadyTaken: "An account for this email already exists."
        case .validation(let message): message
        case .unexpected: "Oops.. Something went wrong."
        }
    }
}
