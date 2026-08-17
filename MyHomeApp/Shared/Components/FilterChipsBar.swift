import SwiftUI

/// Horizontal row of selectable capsules used to filter a list by a single value.
struct FilterChipsBar<Value: Hashable>: View {
    struct Chip: Identifiable {
        let value: Value
        let label: String

        var id: Value { value }

        init(_ value: Value, label: String) {
            self.value = value
            self.label = label
        }
    }

    let chips: [Chip]
    @Binding var selection: Value

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips) { chip in
                    tile(for: chip)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    private func tile(for chip: Chip) -> some View {
        let isSelected = chip.value == selection
        return Button {
            selection = chip.value
        } label: {
            Text(chip.label)
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
