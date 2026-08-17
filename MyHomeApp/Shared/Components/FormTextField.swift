import SwiftUI

/// Labelled single-line text field used by the app's forms.
struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var isMonospaced: Bool = false
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))

            TextField(placeholder, text: $text)
                .font(isMonospaced ? .body.monospaced() : .body)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .foregroundStyle(Color("TextPrimary"))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color("BackgroundTertiary"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
