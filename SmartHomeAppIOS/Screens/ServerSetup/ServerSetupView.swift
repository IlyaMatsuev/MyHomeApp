import SwiftUI

struct ServerSetupView: View {
    @Environment(ServerConfigStore.self) private var serverConfigStore
    @Environment(\.serverConfigService) private var serverConfigService
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
                viewModel = ServerSetupViewModel(
                    mode: mode,
                    store: serverConfigStore,
                    service: serverConfigService
                )
            }
        }
    }
}

#Preview {
    let store = ServerConfigStore(persistence: InMemoryServerConfigPersistence())
    return ServerSetupView()
        .environment(store)
        .task { await store.load() }
}
