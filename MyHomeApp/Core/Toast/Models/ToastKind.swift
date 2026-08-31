import SwiftUI

enum ToastKind: Equatable {
    case error
    case success

    var icon: String {
        switch self {
        case .error: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .error: Color("Danger")
        case .success: Color("Success")
        }
    }
}
