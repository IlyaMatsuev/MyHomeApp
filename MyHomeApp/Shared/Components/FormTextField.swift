import SwiftUI

struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var isMonospaced: Bool = false
    var autocapitalization: TextInputAutocapitalization = .never
    var focus: FocusState<Bool>.Binding?

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
        }
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
