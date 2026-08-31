import SwiftUI

@main
struct MyHomeApp: App {
    private let toastStore: ToastStore
    private let serverConfigStore: ServerConfigStore
    private let sessionStore: SessionStore
    private let favoriteColorsStore: FavoriteColorsStore
    private let registrationStore: RegistrationStore
    private let serverConfigService: any ServerConfigService
    private let deviceService: any DeviceService
    private let scenarioService: any ScenarioService

    init() {
        let serverConfigStore = ServerConfigStore(persistence: UserDefaultsServerConfigPersistence())
        let apiClient = HubAPIClient()
        let sessionStore = SessionStore(
            service: HubAuthService(client: apiClient),
            tokenStore: KeychainTokenStore()
        )
        apiClient.setServerProvider { serverConfigStore.selectedServer }
        apiClient.setTokenProvider { sessionStore.sessionToken }
        apiClient.setRefreshHandler { await sessionStore.refresh() }

        self.toastStore = ToastStore()
        self.favoriteColorsStore = FavoriteColorsStore(persistence: UserDefaultsFavoriteColorsPersistence())
        self.serverConfigStore = serverConfigStore
        self.sessionStore = sessionStore
        self.registrationStore = RegistrationStore(
            service: HubRegistrationService(client: apiClient),
            persistence: UserDefaultsRegistrationPersistence()
        )
        self.serverConfigService = HubServerConfigService(client: apiClient)
        self.deviceService = HubDeviceService(client: apiClient)
        self.scenarioService = HubScenarioService(client: apiClient)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .toastOverlay()
                .environment(sessionStore)
                .environment(favoriteColorsStore)
                .environment(serverConfigStore)
                .environment(registrationStore)
                .environment(\.serverConfigService, serverConfigService)
                .environment(\.deviceService, deviceService)
                .environment(\.scenarioService, scenarioService)
                .environment(toastStore)
        }
    }
}
