import SwiftUI

struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var isMonospaced: Bool = false
    var autocapitalization: TextInputAutocapitalization = .never
    var focus: FocusState<Bool>.Binding?
    var error: String?

    /// Masks the value behind a reveal button — for secrets like a Tuya local key.
    var isSecure: Bool = false

    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))

            field
                .font(isMonospaced ? .body.monospaced() : .body)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .foregroundStyle(Color("TextPrimary"))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color("BackgroundTertiary"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(error == nil ? .clear : Color("Danger"), lineWidth: 1.5)
                }

            if let error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(Color("Danger"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .animation(.spring(duration: 0.25), value: error)
    }

    private var field: some View {
        HStack(spacing: 8) {
            input

            if isSecure {
                revealButton
            }
        }
    }

    /// Both fields stay mounted so revealing the value doesn't drop the keyboard.
    @ViewBuilder
    private var input: some View {
        if isSecure {
            ZStack {
                secureField
                    .opacity(isRevealed ? 0 : 1)
                    .allowsHitTesting(!isRevealed)
                plainField
                    .opacity(isRevealed ? 1 : 0)
                    .allowsHitTesting(isRevealed)
            }
        } else {
            plainField
        }
    }

    @ViewBuilder
    private var plainField: some View {
        if let focus {
            TextField(placeholder, text: $text).focused(focus)
        } else {
            TextField(placeholder, text: $text)
        }
    }

    private var secureField: some View {
        SecureField(placeholder, text: $text)
    }

    private var revealButton: some View {
        Button {
            isRevealed.toggle()
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRevealed ? "Hide \(title)" : "Show \(title)")
    }
}

#Preview {
    @Previewable @State var name = "Office table LED"
    @Previewable @State var key = "a1b2c3d4e5f6"

    return VStack(spacing: 16) {
        FormTextField(title: "Name", placeholder: "Office table LED", text: $name)
        FormTextField(title: "Tuya local key", placeholder: "a1b2c3...", text: $key, isSecure: true)
        FormTextField(title: "IP address", placeholder: "192.168.0.10", text: .constant("nope"),
                      error: "Must be a valid IPv4 address.")
    }
    .padding()
    .background(Color("BackgroundSecondary"))
}
