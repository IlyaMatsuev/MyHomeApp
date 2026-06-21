import SwiftUI

@main
struct SmartHomeAppIOSApp: App {
    private let serverConfigStore: ServerConfigStore
    private let sessionStore: SessionStore
    private let serverConfigService: any ServerConfigService

    init() {
        let serverConfigStore = ServerConfigStore(persistence: UserDefaultsServerConfigPersistence())
        let apiClient = LiveHubAPIClient()
        let sessionStore = SessionStore(
            service: HubAuthService(client: apiClient),
            tokenStore: KeychainTokenStore()
        )
        apiClient.setServerProvider { serverConfigStore.selectedServer }
        apiClient.setTokenProvider { sessionStore.sessionToken }

        self.serverConfigStore = serverConfigStore
        self.sessionStore = sessionStore
        self.serverConfigService = HubServerConfigService(client: apiClient)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionStore)
                .environment(serverConfigStore)
                .environment(\.serverConfigService, serverConfigService)
        }
    }
}
