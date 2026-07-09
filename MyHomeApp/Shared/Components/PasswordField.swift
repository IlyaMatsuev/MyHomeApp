import SwiftUI

struct PasswordField: View {
    @Binding var password: String
    var title: String = "Password"

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                SecureField(title, text: $password)
                    .opacity(isRevealed ? 0 : 1)
                    .allowsHitTesting(!isRevealed)
                TextField(title, text: $password)
                    .opacity(isRevealed ? 1 : 0)
                    .allowsHitTesting(isRevealed)
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "lightbulb.fill" : "lightbulb")
                    .foregroundStyle(isRevealed ? Color("Warning") : Color("TextSecondary").opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
        }
        .padding()
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: isRevealed)
    }
}

#Preview {
    @Previewable @State var password = "hunter2"
    return VStack(spacing: 16) {
        PasswordField(password: $password)
        PasswordField(password: $password, title: "Confirm password")
    }
    .padding()
}
