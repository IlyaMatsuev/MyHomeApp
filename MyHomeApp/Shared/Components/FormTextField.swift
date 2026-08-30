import SwiftUI

struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var isMonospaced: Bool = false
    var autocapitalization: TextInputAutocapitalization = .never
    var focus: FocusState<Bool>.Binding?
    var error: String?

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

    @ViewBuilder
    private var field: some View {
        if let focus {
            TextField(placeholder, text: $text).focused(focus)
        } else {
            TextField(placeholder, text: $text)
        }
    }
}
