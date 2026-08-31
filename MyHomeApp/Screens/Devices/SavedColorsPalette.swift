import SwiftUI

/// The saved colours, shown under every colour field so one palette serves every device.
///
/// The circles wrap rather than scroll: a horizontal scroller inside a scrolling sheet clips its
/// last circle mid-shape and fights the sheet for the drag.
struct SavedColorsPalette: View {
    @Environment(SavedColorsStore.self) private var store

    /// The colour currently in the field: offered for saving, and ringed once it is saved.
    let currentHex: String
    let onSelect: (String) -> Void

    @State private var editedColor: SavedColor?

    private static let diameter: CGFloat = 32

    private let columns = [GridItem(.adaptive(minimum: diameter + 8), spacing: 10)]

    private var normalizedCurrent: String? { currentHex.normalizedHexColor }

    private var canSaveCurrent: Bool {
        guard let normalizedCurrent else { return false }
        return !store.contains(normalizedCurrent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Saved")
                .font(.caption2)
                .foregroundStyle(Color("TextSecondary"))

            if store.colors.isEmpty && !canSaveCurrent {
                Text("Save a color here to reuse it on any device.")
                    .font(.caption2)
                    .foregroundStyle(Color("TextSecondary"))
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    if let normalizedCurrent, canSaveCurrent {
                        saveButton(normalizedCurrent)
                    }

                    ForEach(store.colors) { color in
                        circle(color)
                    }
                }
            }
        }
        .sheet(item: $editedColor) { color in
            SavedColorEditorSheet(color: color) { store.update(color, to: $0) }
        }
    }

    private func saveButton(_ hex: String) -> some View {
        Button {
            store.add(hex)
        } label: {
            Image(systemName: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AccentPrimary"))
                .frame(width: Self.diameter, height: Self.diameter)
                .background(Color("BackgroundTertiary"), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save \(hex)")
    }

    private func circle(_ color: SavedColor) -> some View {
        let isSelected = color.hex == normalizedCurrent

        return Button {
            onSelect(color.hex)
        } label: {
            Circle()
                .fill(Color(hex: color.hex) ?? Color("BackgroundTertiary"))
                .frame(width: Self.diameter, height: Self.diameter)
                .overlay {
                    // `strokeBorder`, not `stroke`: a centred stroke spills half its width past the
                    // frame, and the press platter clips to the frame — flattening the ring's edges.
                    Circle().strokeBorder(
                        isSelected ? Color("AccentPrimary") : Color("TextSecondary").opacity(0.3),
                        lineWidth: isSelected ? 2.5 : 1
                    )
                }
        }
        .buttonStyle(.plain)
        .contentShape(.contextMenuPreview, Circle())
        .accessibilityLabel("Saved color \(color.hex)")
        .contextMenu {
            Button {
                editedColor = color
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                store.remove(color)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

#Preview {
    SavedColorsPalette(currentHex: "#B7D4FF") { _ in }
        .padding()
        .background(Color("BackgroundSecondary"))
        .environment(SavedColorsStore(
            persistence: InMemorySavedColorsPersistence(
                initial: ["#FF7A45", "#4ADE80", "#B7D4FF", "#F43F5E", "#FACC15",
                          "#8B5CF6", "#06B6D4", "#111827", "#EC4899"].map { SavedColor(hex: $0) }
            )
        ))
}
