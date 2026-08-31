import SwiftUI

/// The editable identity of a device: everything `PUT /devices/:externalId` accepts.
struct DeviceDetailsForm: View {
    @Bindable var viewModel: DeviceDetailViewModel

    var body: some View {
        CardSection(title: "Details") {
            FormTextField(
                title: "Name",
                placeholder: "Office table LED",
                text: $viewModel.draft.name,
                autocapitalization: .sentences,
                error: viewModel.detailsError(for: .name)
            )

            picker("Room", selection: $viewModel.draft.room) { $0.label }
            picker("Type", selection: $viewModel.draft.type) { $0.label }
            picker("Brand", selection: $viewModel.draft.brand) { $0.label }
            picker("Protocol", selection: $viewModel.draft.transportProtocol) { $0.label }

            if viewModel.draft.showsIPField {
                FormTextField(
                    title: "IP address",
                    placeholder: "192.168.0.10",
                    text: $viewModel.draft.ip,
                    error: viewModel.detailsError(for: .ip)
                )
            }

            if viewModel.draft.showsUpdateIntervalField {
                FormTextField(
                    title: "Update interval (ms)",
                    placeholder: "Optional",
                    text: $viewModel.draft.updateInterval,
                    error: viewModel.detailsError(for: .updateInterval)
                )
            }

            if viewModel.draft.showsTuyaFields {
                FormTextField(
                    title: "Tuya device ID",
                    placeholder: "eb0c1f...",
                    text: $viewModel.draft.tuyaDeviceId,
                    error: viewModel.detailsError(for: .tuyaDeviceId),
                    isSecure: true
                )
                FormTextField(
                    title: "Tuya local key",
                    placeholder: "a1b2c3...",
                    text: $viewModel.draft.tuyaDeviceLocalKey,
                    error: viewModel.detailsError(for: .tuyaDeviceLocalKey),
                    isSecure: true
                )
            }

            if viewModel.draft.showsZigbeeFields {
                FormTextField(
                    title: "Zigbee friendly name",
                    placeholder: "MainLightRemote",
                    text: $viewModel.draft.zigbeeFriendlyName,
                    error: viewModel.detailsError(for: .zigbeeFriendlyName)
                )

                if let address = viewModel.device.zigbeeIeeeAddress {
                    readOnly("IEEE address", value: address)
                }
            }

            if let message = viewModel.detailsErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color("Danger"))
            }
        }
    }

    private func picker<Value: Hashable & CaseIterable>(
        _ title: String,
        selection: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))

            Spacer(minLength: 12)

            Picker(title, selection: selection) {
                ForEach(Array(Value.allCases), id: \.self) { value in
                    Text(label(value)).tag(value)
                }
            }
            .labelsHidden()
            .tint(Color("AccentPrimary"))
        }
    }

    private func readOnly(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(Color("TextPrimary"))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
