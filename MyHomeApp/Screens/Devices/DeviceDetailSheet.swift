import SwiftUI

/// Everything one device can do, built from the config the hub ships for it.
struct DeviceDetailSheet: View {
    @Bindable var viewModel: DeviceDetailViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()
                content
            }
            .navigationTitle(viewModel.device.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .confirmationDialog(
                "Delete this device?",
                isPresented: $viewModel.isConfirmingDeletion,
                titleVisibility: .visible
            ) {
                Button("Delete \"\(viewModel.device.name)\"", role: .destructive) {
                    Task { await viewModel.confirmDeletion() }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDeletion()
                }
            } message: {
                Text("The hub forgets it entirely. Scenarios that use it stop working.")
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DeviceDetailsForm(viewModel: viewModel)

                if !viewModel.controlItems.isEmpty {
                    DeviceControlsSection(viewModel: viewModel)
                }

                if !viewModel.commandItems.isEmpty {
                    DeviceCommandsSection(viewModel: viewModel)
                }

                if !viewModel.measurementItems.isEmpty {
                    DeviceMeasurementsSection(device: viewModel.device)
                }

                deleteButton
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Done") { dismiss() }
                .disabled(viewModel.isBusy)
        }
        ToolbarItem(placement: .confirmationAction) {
            if viewModel.isSavingDetails {
                ProgressView()
            } else {
                Button("Save") {
                    Task { await viewModel.saveDetails() }
                }
                .disabled(!viewModel.canSaveDetails)
                .opacity(viewModel.canSaveDetails ? 1 : 0.5)
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.requestDeletion()
        } label: {
            HStack(spacing: 8) {
                if viewModel.isDeleting {
                    ProgressView().controlSize(.small)
                }
                Label("Delete Device", systemImage: "trash")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Color("Danger"))
        .disabled(viewModel.isBusy)
        .padding(.top, 8)
    }
}

#Preview {
    let device = MockDeviceService.allDevices[3]
    return DeviceDetailSheet(
        viewModel: DeviceDetailViewModel(
            device: device,
            service: MockDeviceService(operationDelay: .milliseconds(300)),
            toastStore: ToastStore(),
            onChanged: { _ in },
            onDeleted: { _ in }
        )
    )
    .environment(FavoriteColorsStore(persistence: InMemoryFavoriteColorsPersistence()))
}
