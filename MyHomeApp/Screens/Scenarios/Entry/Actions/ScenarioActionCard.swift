import SwiftUI

struct ScenarioActionCard: View {
    let viewModel: ScenarioEditorViewModel
    @Binding var action: ScenarioActionDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            ScenarioDevicePicker(
                devices: viewModel.devices,
                selectedDeviceId: action.deviceId,
                onSelect: { viewModel.selectDevice($0, forAction: action) }
            )

            controlField

            Toggle(action.value ? "Turn on" : "Turn off", isOn: $action.value)
                .tint(Color("AccentPrimary"))
                .foregroundStyle(Color("TextPrimary"))
        }
        .padding(12)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("Set a device control", systemImage: "slider.horizontal.3")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color("TextPrimary"))

            Spacer()

            Button {
                viewModel.removeAction(action)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color("Danger"))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove action")
        }
    }

    @ViewBuilder
    private var controlField: some View {
        let keys = viewModel.toggleControlKeys(ofDeviceId: action.deviceId)

        if keys.isEmpty {
            FormTextField(title: "Control name", placeholder: "on", text: $action.controlKey)
        } else {
            Picker("Control", selection: $action.controlKey) {
                ForEach(keys, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .tint(Color("AccentPrimary"))
        }
    }
}
