import SwiftUI

enum ToastKind: Equatable {
    case error

    var icon: String {
        switch self {
        case .error: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .error: Color("Danger")
        }
    }
}
