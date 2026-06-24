import SwiftUI
import PopupView

struct ToastOverlay: ViewModifier {
    @Environment(ToastStore.self) private var store

    func body(content: Content) -> some View {
        content.popup(item: Binding(
            get: { store.current },
            set: { if $0 == nil { store.dismiss() } }
        )) { toast in
            ToastView(toast: toast)
        } customize: {
            $0.type(.floater())
              .position(.bottom)
              .autohideIn(3)
              .dragToDismiss(true)
              .closeOnTapOutside(false)
              .closeOnTap(true)
        }
    }
}
