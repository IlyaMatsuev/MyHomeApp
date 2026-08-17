import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .foregroundStyle(
                    isSelected ? Color("TextPrimary") : Color("TextSecondary")
                )
                .background(
                    Capsule()
                        .fill(isSelected ? Color("AccentPrimary") : Color("BackgroundSecondary"))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
