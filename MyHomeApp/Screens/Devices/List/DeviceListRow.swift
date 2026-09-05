import SwiftUI
import AnyCodable

struct DeviceListRow: View {
    let device: Device
    let viewModel: DevicesViewModel
    let onOpenDetails: (Device) -> Void

    @State private var commandText = ""

    private var loading: Bool { viewModel.isLoading(device) }

    private var toggleItem: DeviceConfigItem? {
        DeviceRowLayout.controlItems(of: device).first { $0.type == .boolean }
    }

    private var sliderItems: [DeviceConfigItem] {
        DeviceRowLayout.controlItems(of: device).filter { $0.type == .number }
    }

    private var commandItem: DeviceConfigItem? {
        DeviceRowLayout.commandItems(of: device).first { $0.type == .string }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            ForEach(sliderItems) { item in
                slider(for: item)
            }

            if let commandItem {
                commandField(for: commandItem)
            }

            if let summary = DeviceRowLayout.measurementsSummary(of: device) {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onOpenDetails(device) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text(device.type.emoji)
                .font(.title3)
                .foregroundStyle(Color("AccentPrimary"))
                .frame(width: 36, height: 36)
                .background(Color("BackgroundTertiary"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body)
                    .foregroundStyle(Color("TextPrimary"))

                Text("\(device.type.label) · \(device.brand.label)")
                    .font(.subheadline)
                    .foregroundStyle(Color("TextSecondary"))
            }

            Spacer(minLength: 12)

            if loading {
                ProgressView().controlSize(.small)
            }

            if let toggleItem {
                toggle(for: toggleItem)
            }
        }
    }

    // MARK: - Main controls

    private func toggle(for item: DeviceConfigItem) -> some View {
        Toggle("", isOn: Binding(
            get: { DeviceConfigValue.bool(device.controlValue(of: item)) ?? false },
            set: { viewModel.setControl(device.id, name: item.name, to: AnyCodable($0)) }
        ))
        .labelsHidden()
        .tint(Color("AccentPrimary"))
        .disabled(loading)
        .accessibilityLabel(item.label)
    }

    @ViewBuilder
    private func slider(for item: DeviceConfigItem) -> some View {
        let range = item.constraints?.numericRange ?? 0...100

        HStack(spacing: 12) {
            Image(systemName: "sun.max.fill")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))

            Slider(
                value: Binding(
                    get: { clamped(device.controlValue(of: item), to: range) },
                    set: { viewModel.stageControl(device.id, name: item.name, value: AnyCodable($0)) }
                ),
                in: range,
                step: item.constraints?.numericStep ?? 1
            ) { editing in
                if !editing {
                    Task { await viewModel.commitControl(device.id, name: item.name) }
                }
            }
            .tint(Color("AccentPrimary"))
            .disabled(loading)
            .accessibilityLabel(item.label)

            Text(DeviceConfigValue.text(of: device.controlValue(of: item), for: item))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color("TextSecondary"))
                .frame(minWidth: 32, alignment: .trailing)
        }
    }

    private func commandField(for item: DeviceConfigItem) -> some View {
        HStack(spacing: 8) {
            TextField(item.label, text: $commandText)
                .font(.subheadline)
                .textInputAutocapitalization(.sentences)
                .foregroundStyle(Color("TextPrimary"))
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .background(Color("BackgroundTertiary"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onSubmit { send(item) }

            Button { send(item) } label: {
                Image(systemName: "paperplane.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color("AccentPrimary"))
            }
            .buttonStyle(.plain)
            .disabled(commandText.isBlank || loading)
            .opacity(commandText.isBlank || loading ? 0.4 : 1)
            .accessibilityLabel("Send \(item.label)")
        }
    }

    private func send(_ item: DeviceConfigItem) {
        let text = commandText.trimmed
        guard !text.isEmpty else { return }
        commandText = ""

        Task {
            await viewModel.sendCommand(device.id, name: item.name, value: AnyCodable(text), label: item.label)
        }
    }

    private func clamped(_ value: AnyCodable?, to range: ClosedRange<Double>) -> Double {
        let number = DeviceConfigValue.number(value) ?? range.lowerBound
        return min(max(number, range.lowerBound), range.upperBound)
    }
}
