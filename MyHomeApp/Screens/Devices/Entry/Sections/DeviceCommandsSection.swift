import SwiftUI
import AnyCodable

/// Stateless commands the device accepts. Nothing is stored — each one is fired on demand.
struct DeviceCommandsSection: View {
    @Bindable var viewModel: DeviceDetailViewModel

    var body: some View {
        CardSection(title: "Commands", subtitle: "Sent once, not stored on the device", spacing: 16) {
            ForEach(viewModel.commandItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    DeviceConfigItemEditor(
                        item: item,
                        value: binding(for: item),
                        isBusy: viewModel.isBusyCommand(item),
                        isDisabled: viewModel.isDeleting || !item.isEditable,
                        errorMessage: viewModel.commandError(of: item),
                        commitsOnChange: false
                    ) {
                        send(item)
                    }

                    Button {
                        send(item)
                    } label: {
                        Label("Send", systemImage: "paperplane.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentPrimary"))
                    .disabled(!viewModel.canSend(item) || viewModel.isDeleting)
                }

                if item.id != viewModel.commandItems.last?.id {
                    Divider().overlay(Color("BackgroundTertiary"))
                }
            }
        }
    }

    private func send(_ item: DeviceConfigItem) {
        Task { await viewModel.sendCommand(item) }
    }

    private func binding(for item: DeviceConfigItem) -> Binding<AnyCodable> {
        Binding(
            get: { viewModel.commandValue(of: item) },
            set: { viewModel.setCommandValue($0, of: item) }
        )
    }
}
