import SwiftUI

@main
struct SmartHomeAppIOSApp: App {
    private let toastStore: ToastStore
    private let serverConfigStore: ServerConfigStore
    private let sessionStore: SessionStore
    private let serverConfigService: any ServerConfigService
    private let deviceService: any DeviceService

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
        self.serverConfigStore = serverConfigStore
        self.sessionStore = sessionStore
        self.serverConfigService = HubServerConfigService(client: apiClient)
        self.deviceService = HubDeviceService(client: apiClient)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .toastOverlay()
                .environment(sessionStore)
                .environment(serverConfigStore)
                .environment(\.serverConfigService, serverConfigService)
                .environment(\.deviceService, deviceService)
                .environment(toastStore)
        }
    }
}
