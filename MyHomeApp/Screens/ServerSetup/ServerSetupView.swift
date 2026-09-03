import SwiftUI

struct ServerSetupView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: ServerSetupViewModel?

    var mode: ServerSetupMode = .initialSetup

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            if let viewModel {
                ServerSetupForm(viewModel: viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if viewModel == nil {
                viewModel = container.buildServerSetupViewModel(mode: mode)
            }
        }
    }
}

#Preview {
    ServerSetupView().inject(AppContainer.preview().build())
}
