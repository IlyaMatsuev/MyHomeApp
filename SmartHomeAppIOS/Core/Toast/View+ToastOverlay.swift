import SwiftUI

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlay())
    }
}
