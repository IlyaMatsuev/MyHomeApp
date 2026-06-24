import Foundation

struct Toast: Equatable, Identifiable {
    let id = UUID()
    let message: String
    let kind: ToastKind
}
