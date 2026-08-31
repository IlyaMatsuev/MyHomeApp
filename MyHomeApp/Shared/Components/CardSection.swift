import SwiftUI

/// A titled card used to group related fields on a sheet.
struct CardSection<Content: View>: View {
    let title: String
    var subtitle: String?
    var spacing: CGFloat = 12
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: spacing) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    CardSection(title: "Controls", subtitle: "Applied as soon as you change them") {
        Toggle("On", isOn: .constant(true))
        Text("Brightness")
    }
    .padding()
    .background(Color("BackgroundPrimary"))
}
