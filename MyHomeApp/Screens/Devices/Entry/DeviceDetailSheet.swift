import SwiftUI

@MainActor
struct DeviceDetailSheet: View {
    let device: Device
    let onChanged: @MainActor (Device) -> Void
    let onDeleted: @MainActor (String) -> Void

    @Environment(AppContainer.self) private var container
    @State private var viewModel: DeviceDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                DeviceDetailScreen(viewModel: viewModel)
            } else {
                ZStack {
                    Color("BackgroundPrimary").ignoresSafeArea()
                    ProgressView()
                }
            }
        }
        .onAppear {
            guard viewModel == nil else { return }
            viewModel = container.buildDeviceDetailsViewModel(
                device: device,
                onChanged: onChanged,
                onDeleted: onDeleted,
            )
        }
    }
}

#Preview {
    DeviceDetailSheet(
        device: MockDeviceService.allDevices[3],
        onChanged: { _ in },
        onDeleted: { _ in }
    )
    .inject(AppContainer.preview().build())
}
