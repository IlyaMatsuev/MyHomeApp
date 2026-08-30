import SwiftUI

struct ScenarioDevicePicker: View {
    let devices: [Device]
    let selectedDeviceId: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Device")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))

            Menu {
                menuContent
            } label: {
                label
            }
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        if devices.isEmpty {
            Button("No devices available") {}
                .disabled(true)
        } else {
            ForEach(devices) { device in
                Button {
                    onSelect(device.externalId)
                } label: {
                    if device.externalId == selectedDeviceId {
                        Label(device.name, systemImage: "checkmark")
                    } else {
                        Text(device.name)
                    }
                }
            }
        }
    }

    private var label: some View {
        HStack(spacing: 8) {
            Text(selectedDeviceName)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(isDeviceSelected ? Color("TextPrimary") : Color("TextSecondary"))

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(Color("TextSecondary"))
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(Color("BackgroundTertiary"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var isDeviceSelected: Bool {
        devices.contains { $0.externalId == selectedDeviceId }
    }

    private var selectedDeviceName: String {
        devices.first { $0.externalId == selectedDeviceId }?.name ?? "Select a device"
    }
}
