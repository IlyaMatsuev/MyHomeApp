import SwiftUI

struct ScenariosView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: ScenariosViewModel?

    var body: some View {
        Group {
            if let viewModel {
                ScenarioScreen(viewModel: viewModel)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard viewModel == nil else { return }
            let newViewModel = container.buildScenariosViewModel()
            viewModel = newViewModel
            await newViewModel.load()
        }
    }
}

#Preview {
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    return ScenariosView().inject(AppContainer.preview().withServers([server]).build())
}
