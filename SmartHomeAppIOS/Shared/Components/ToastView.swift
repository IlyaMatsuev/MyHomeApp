import SwiftUI

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.kind.icon)
            Text(toast.message)
                .font(.callout)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toast.kind.color, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview("Error") {
    let toast = Toast(message: "Oops... Something went wrong", kind: ToastKind.error)
    ToastView(toast: toast)
}
