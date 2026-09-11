import SwiftUI

struct DevicesView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: DevicesViewModel?

    var body: some View {
        Group {
            if let viewModel {
                DevicesScreen(viewModel: viewModel)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard viewModel == nil else { return }
            let newViewModel = container.buildDevicesViewModel()
            viewModel = newViewModel
            await newViewModel.load()
        }
    }
}

#Preview {
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    return DevicesView().inject(AppContainer.preview().withServers([server]).build())
}
