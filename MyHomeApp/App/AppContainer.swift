import SwiftUI

@Observable
@MainActor
final class AppContainer {
    let sessionStore: SessionStore
    let serverConfigStore: ServerConfigStore
    let registrationStore: RegistrationStore
    let savedColorsStore: SavedColorsStore
    let toastStore: ToastStore

    private let serverConfigService: any ServerConfigService
    private let deviceService: any DeviceService
    private let scenarioService: any ScenarioService

    init(
        serverConfigPersistence: any ServerConfigPersistence = UserDefaultsServerConfigPersistence(),
        savedColorsPersistence: any SavedColorsPersistence = UserDefaultsSavedColorsPersistence(),
        registrationPersistence: any RegistrationPersistence = UserDefaultsRegistrationPersistence(),
        tokenPersistence: any AuthTokenPersistence = KeychainAuthTokenPersistance(),
        urlSession: URLSession = .shared
    ) {
        let serverConfigStore = ServerConfigStore(persistence: serverConfigPersistence)
        let apiClient = HubAPIClient(session: urlSession)
        let sessionStore = SessionStore(
            service: HubAuthService(client: apiClient),
            tokenPersistence: tokenPersistence
        )
        apiClient.setServerProvider { serverConfigStore.selectedServer }
        apiClient.setTokenProvider { sessionStore.sessionToken }
        apiClient.setRefreshHandler { await sessionStore.refresh() }

        self.serverConfigStore = serverConfigStore
        self.sessionStore = sessionStore
        self.toastStore = ToastStore()
        self.savedColorsStore = SavedColorsStore(persistence: savedColorsPersistence)
        self.registrationStore = RegistrationStore(
            service: HubRegistrationService(client: apiClient),
            persistence: registrationPersistence
        )
        self.serverConfigService = HubServerConfigService(client: apiClient)
        self.deviceService = HubDeviceService(client: apiClient)
        self.scenarioService = HubScenarioService(client: apiClient)
    }

    static func live() -> AppContainer {
        return AppContainer()
    }

    // MARK: - Screen view models
    func buildLoginViewModel() -> LoginViewModel {
        
    }

    func buildRegisterViewModel(email: String) -> RegisterViewModel {
        
    }

    func buildRegistrationRequestViewModel() -> RegistrationRequestViewModel {
        
    }

    func buildRegistrationStatusViewModel() -> RegistrationStatusViewModel {
        
    }

    func buildServerSetupViewModel() -> ServerSetupViewModel {
        
    }

    func buildDevicesViewModel() -> DevicesViewModel {
        
    }

    func BuildScenariosViewModel() -> ScenariosViewModel {
        
    }
}
