import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(ServerConfigStore.self) private var serverConfigStore
    @Environment(RegistrationStore.self) private var registrationStore

    @State private var displayStage: Stage = .loading

    enum Stage: Hashable {
        case loading
        case serverSetup
        case login
        case main
    }

    private var stage: Stage {
        switch (serverConfigStore.state, sessionStore.state) {
        case (.loading, _), (_, .loading): .loading
        case (.unconfigured, _): .serverSetup
        case (.configured, .authenticated): .main
        case (.configured, .unauthenticated): .login
        }
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            currentScreen.id(displayStage)
        }
        .task {
            await serverConfigStore.load()
            await sessionStore.load()
            await registrationStore.load()
        }
        .onChange(of: stage, initial: true) { _, newValue in
            withAnimation(.easeInOut(duration: 0.35)) {
                displayStage = newValue
            }
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch displayStage {
        case .loading:
            ProgressView()
        case .serverSetup:
            ServerSetupView()
        case .login:
            LoginView()
        case .main:
            ContentView()
        }
    }
}

#Preview("Unconfigured") {
    let sessionStore = SessionStore(service: MockAuthService(), tokenStore: InMemoryTokenStore())
    let registrationStore = RegistrationStore(
        service: MockRegistrationService(),
        persistence: InMemoryRegistrationPersistence()
    )
    let serverConfigStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence())
    return RootView()
        .environment(sessionStore)
        .environment(registrationStore)
        .environment(serverConfigStore)
}

#Preview("Unconfigured (live)") {
    let serverConfigStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence())
    let apiClient = HubAPIClient()
    let sessionStore = SessionStore(
        service: HubAuthService(client: apiClient),
        tokenStore: InMemoryTokenStore()
    )
    apiClient.setServerProvider { serverConfigStore.selectedServer }
    apiClient.setTokenProvider { sessionStore.sessionToken }

    let registrationStore = RegistrationStore(
        service: HubRegistrationService(client: apiClient),
        persistence: InMemoryRegistrationPersistence()
    )
    let serverConfigService = HubServerConfigService(client: apiClient)
    return RootView()
        .environment(sessionStore)
        .environment(registrationStore)
        .environment(serverConfigStore)
        .environment(\.serverConfigService, serverConfigService)
}

#Preview("Configured and signed out") {
    let sessionStore = SessionStore(service: MockAuthService(), tokenStore: InMemoryTokenStore())
    let registrationStore = RegistrationStore(
        service: MockRegistrationService(),
        persistence: InMemoryRegistrationPersistence()
    )
    let serverConfig = Server(.http, "hub.local:8080", remote: false)
    let serverConfigStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: [serverConfig]))
    return RootView()
        .environment(sessionStore)
        .environment(registrationStore)
        .environment(serverConfigStore)
}
