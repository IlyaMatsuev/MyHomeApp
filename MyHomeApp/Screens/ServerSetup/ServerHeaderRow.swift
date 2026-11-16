import SwiftUI

struct ServerHeaderRow: View {
    @Binding var header: ServerHeader
    let nameError: String?
    let valueError: String?

    var body: some View {
        VStack(spacing: 12) {
            FormTextField(
                title: "Name",
                placeholder: "X-Proxy-Authorization",
                text: $header.name,
                isMonospaced: true,
                error: nameError
            )
            FormTextField(
                title: "Value",
                placeholder: "Token",
                text: $header.value,
                isMonospaced: true,
                error: valueError,
                isSecure: true
            )
        }
        .padding(12)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
