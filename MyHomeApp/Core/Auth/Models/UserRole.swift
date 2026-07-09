import SwiftUI

enum UserRole: String, Codable, Sendable {
    case admin
    case resident
    case guest

    var label: String {
        switch self {
        case .admin: "Admin"
        case .resident: "Resident"
        case .guest: "Guest"
        }
    }

    var color: Color {
        switch self {
        case .admin: Color("AccentSecondary")
        case .resident: Color("AccentPrimary")
        case .guest: Color("Success")
        }
    }
}
