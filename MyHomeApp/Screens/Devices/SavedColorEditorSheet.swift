import SwiftUI

/// Changes the color a saved swatch stands for, reached by long pressing it.
struct SavedColorEditorSheet: View {
    let color: SavedColor
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var hex: String

    init(color: SavedColor, onSave: @escaping (String) -> Void) {
        self.color = color
        self.onSave = onSave
        _hex = State(initialValue: color.hex)
    }

    private var isValid: Bool { hex.normalizedHexColor != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        ColorPicker("Color", selection: colorBinding, supportsOpacity: false)
                            .labelsHidden()

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: hex) ?? Color("BackgroundTertiary"))
                            .frame(height: 44)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color("TextSecondary").opacity(0.3), lineWidth: 1)
                            }
                    }

                    FormTextField(
                        title: "Hex value",
                        placeholder: "#RRGGBB",
                        text: $hex,
                        isMonospaced: true,
                        error: isValid ? nil : "Must be a hex color, like #B7D4FF."
                    )

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationTitle("Edit Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(hex)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.height(280)])
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: hex) ?? Color("BackgroundTertiary") },
            set: { newColor in
                if let picked = newColor.hexString {
                    hex = picked
                }
            }
        )
    }
}

#Preview {
    SavedColorEditorSheet(color: SavedColor(hex: "#FF7A45")) { _ in }
}
