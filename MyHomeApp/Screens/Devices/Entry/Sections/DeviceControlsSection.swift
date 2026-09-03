import SwiftUI
import AnyCodable

/// Every control the device's config declares, each applied on its own.
struct DeviceControlsSection: View {
    @Bindable var viewModel: DeviceDetailViewModel

    var body: some View {
        CardSection(title: "Controls", subtitle: "Changes are sent to the device as you make them", spacing: 16) {
            ForEach(viewModel.controlItems) { item in
                DeviceConfigItemEditor(
                    item: item,
                    value: binding(for: item),
                    isBusy: viewModel.isBusyControl(item),
                    isDisabled: viewModel.isDeleting || !item.isEditable,
                    errorMessage: viewModel.controlError(of: item),
                    isDirty: viewModel.isControlDirty(item)
                ) {
                    Task { await viewModel.commitControl(item) }
                }

                if item.id != viewModel.controlItems.last?.id {
                    Divider().overlay(Color("BackgroundTertiary"))
                }
            }
        }
    }

    private func binding(for item: DeviceConfigItem) -> Binding<AnyCodable> {
        Binding(
            get: { viewModel.controlValue(of: item) },
            set: { viewModel.setControlValue($0, of: item) }
        )
    }
}
