import SwiftUI

/// One trigger source inside the editor. The number matches the index used by a custom logic expression.
struct ScenarioSourceCard: View {
    let viewModel: ScenarioEditorViewModel
    @Binding var source: ScenarioSourceDraft

    let number: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            switch source.kind {
            case .cron:
                cronFields

            case .device:
                deviceFields
            }
        }
        .padding(12)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color("AccentPrimary")))

            Label(source.kind.label, systemImage: source.kind.iconSystemName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color("TextPrimary"))

            Spacer()

            Button {
                viewModel.removeSource(source)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color("Danger"))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove trigger \(number)")
        }
    }

    private var cronFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            FormTextField(
                title: "Cron expression",
                placeholder: "0 8 * * *",
                text: $source.cron,
                isMonospaced: true
            )

            Text("minute hour day-of-month month day-of-week")
                .font(.caption2)
                .foregroundStyle(Color("TextSecondary"))

            Picker("Adjust to", selection: $source.adjustTo) {
                Text("Exact time").tag(ScenarioSolarAdjustment?.none)
                ForEach(ScenarioSolarAdjustment.allCases) { adjustment in
                    Text(adjustment.label).tag(Optional(adjustment))
                }
            }
            .tint(Color("AccentPrimary"))
        }
    }

    private var deviceFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScenarioDevicePicker(
                devices: viewModel.devices,
                selectedDeviceId: source.deviceId,
                onSelect: { viewModel.selectDevice($0, forSource: source) }
            )

            Picker("Match", selection: matchKindBinding) {
                ForEach(ScenarioSourceDraft.MatchKind.allCases) { matchKind in
                    Text(matchKind.label).tag(matchKind)
                }
            }
            .pickerStyle(.segmented)

            switch source.matchKind {
            case .command:
                commandFields

            case .control:
                controlFields
            }
        }
    }

    private var commandFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            FormTextField(title: "Command name", placeholder: "action", text: $source.matchKey)
            FormTextField(title: "Command value", placeholder: "up_press", text: $source.matchCommand)
        }
    }

    private var controlFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            let keys = viewModel.toggleControlKeys(ofDeviceId: source.deviceId)

            if keys.isEmpty {
                FormTextField(title: "Control name", placeholder: "on", text: $source.matchKey)
            } else {
                Picker("Control", selection: $source.matchKey) {
                    ForEach(keys, id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .tint(Color("AccentPrimary"))
            }

            Toggle("Is on", isOn: $source.matchValue)
                .tint(Color("AccentPrimary"))
                .foregroundStyle(Color("TextPrimary"))
        }
    }

    private var matchKindBinding: Binding<ScenarioSourceDraft.MatchKind> {
        Binding(
            get: { source.matchKind },
            set: { viewModel.selectMatchKind($0, forSource: source) }
        )
    }
}
