import SwiftUI
import AnyCodable

/// Renders the right editor for one command/control from its config metadata.
///
/// The layout is chosen entirely from `item.type` + `constraints` + `values`, so a device the hub
/// describes differently gets a different form without a code change here.
struct DeviceConfigItemEditor: View {
    let item: DeviceConfigItem
    @Binding var value: AnyCodable

    var isBusy = false
    var isDisabled = false
    var errorMessage: String?

    /// Shows the apply button next to a free-text field once its value differs from the device's.
    var isDirty = false

    /// `false` for a command, where flipping a toggle only drafts the value and Send fires it.
    var commitsOnChange = true

    /// Called once the edit is meant to leave the device: a released slider, a submitted field, a
    /// flipped toggle. Free-text edits also surface an apply button.
    let onCommit: () -> Void

    @State private var text = ""
    @FocusState private var isTextFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            editor
                .disabled(isDisabled || isBusy)

            if let description = item.description, !description.isBlank {
                caption(description)
            }

            if isColor {
                FavoriteColorsPalette(currentHex: text) { apply($0) }
                    .disabled(isDisabled || isBusy)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(Color("Danger"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: item.name) { syncText() }
        .onChange(of: value) { _, _ in
            if !isTextFocused {
                syncText()
            }
        }
    }

    // MARK: - Per-type editors

    @ViewBuilder
    private var editor: some View {
        switch item.type {
        case .boolean:
            Toggle(isOn: boolBinding) {
                label
            }
            .tint(Color("AccentPrimary"))

        case .number:
            if let range = item.constraints?.numericRange {
                sliderEditor(range: range)
            } else {
                textEditor(keyboard: .decimalPad)
            }

        case .enumeration:
            HStack {
                label
                Spacer(minLength: 12)
                Picker(item.label, selection: enumBinding) {
                    ForEach(item.options) { option in
                        Text(option.label).tag(option.name)
                    }
                }
                .labelsHidden()
                .tint(Color("AccentPrimary"))
            }

        case .string:
            textEditor(keyboard: .default)

        case .object, .unsupported:
            readOnlyEditor
        }
    }

    private func sliderEditor(range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                label
                Spacer(minLength: 12)
                if isBusy {
                    ProgressView().controlSize(.small)
                }
                Text(DeviceConfigValue.text(of: value, for: item))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color("TextSecondary"))
            }

            Slider(
                value: numberBinding(in: range),
                in: range,
                step: item.constraints?.numericStep ?? 1
            ) { editing in
                if !editing, commitsOnChange {
                    onCommit()
                }
            }
            .tint(Color("AccentPrimary"))
        }
    }

    private func textEditor(keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label

            HStack(spacing: 8) {
                if isColor {
                    colorPicker
                }

                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(item.type == .string ? .sentences : .never)
                    .autocorrectionDisabled()
                    .focused($isTextFocused)
                    .foregroundStyle(Color("TextPrimary"))
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Color("BackgroundTertiary"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onChange(of: text) { _, newValue in
                        value = parsed(newValue)
                    }
                    .onSubmit(onCommit)

                if isBusy {
                    ProgressView().controlSize(.small)
                } else if isDirty {
                    applyButton
                }
            }
        }
    }

    private var readOnlyEditor: some View {
        HStack(alignment: .firstTextBaseline) {
            label
            Spacer(minLength: 12)
            Text(DeviceConfigValue.text(of: value, for: item))
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .lineLimit(2)
        }
    }

    // MARK: - Building blocks

    /// Hints at the shape the hub expects, since the label already sits above the field.
    private var placeholder: String {
        if isColor {
            return "#RRGGBB"
        }
        if let range = item.constraints?.numericRange {
            let integer = item.constraints?.integer == true
            return "\(DeviceConfigValue.format(range.lowerBound, integer: integer))"
                + "–\(DeviceConfigValue.format(range.upperBound, integer: integer))"
        }
        return "Value"
    }

    private var label: some View {
        Text(item.label)
            .font(.subheadline)
            .foregroundStyle(Color("TextPrimary"))
    }

    private var applyButton: some View {
        Button(action: onCommit) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color("AccentPrimary"))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Apply \(item.label)")
    }

    private var isColor: Bool { item.constraints?.format == .hexColor }

    /// The system picker, so the swatch itself is what opens it.
    private var colorPicker: some View {
        ColorPicker(item.label, selection: colorBinding, supportsOpacity: false)
            .labelsHidden()
    }

    private func caption(_ message: String) -> some View {
        Text(message)
            .font(.caption2)
            .foregroundStyle(Color("TextSecondary"))
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Bindings

    private var boolBinding: Binding<Bool> {
        Binding(
            get: { DeviceConfigValue.bool(value) ?? false },
            set: { newValue in
                value = AnyCodable(newValue)
                if commitsOnChange {
                    onCommit()
                }
            }
        )
    }

    private var enumBinding: Binding<String> {
        Binding(
            get: { DeviceConfigValue.string(value) ?? item.options.first?.name ?? "" },
            set: { newValue in
                value = AnyCodable(newValue)
                if commitsOnChange {
                    onCommit()
                }
            }
        )
    }

    /// Dragging the picker only drafts the colour — the apply button sends it, so one pick isn't a
    /// stream of requests.
    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: text) ?? Color("BackgroundTertiary") },
            set: { picked in
                guard let hex = picked.hexString else { return }
                text = hex
                value = AnyCodable(hex)
            }
        )
    }

    private func numberBinding(in range: ClosedRange<Double>) -> Binding<Double> {
        Binding(
            get: { min(max(DeviceConfigValue.number(value) ?? range.lowerBound, range.lowerBound), range.upperBound) },
            set: { value = AnyCodable($0) }
        )
    }

    // MARK: - Text <-> value

    private func syncText() {
        text = DeviceConfigValue.string(value) ?? DeviceConfigValue.number(value).map {
            DeviceConfigValue.format($0, integer: item.constraints?.integer == true)
        } ?? ""
    }

    /// A favourite is a shortcut, so picking one also sends it wherever the editor commits on change.
    private func apply(_ hex: String) {
        text = hex
        value = AnyCodable(hex)
        if commitsOnChange {
            onCommit()
        }
    }

    /// Keeps unparseable input as-is so the mirrored validation can explain what's wrong.
    private func parsed(_ input: String) -> AnyCodable {
        guard item.type == .number else { return AnyCodable(input) }
        return Double(input).map { AnyCodable($0) } ?? AnyCodable(input)
    }
}
