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
        sessionStore: SessionStore,
        serverConfigStore: ServerConfigStore,
        registrationStore: RegistrationStore,
        savedColorsStore: SavedColorsStore,
        toastStore: ToastStore,

        serverConfigService: any ServerConfigService,
        deviceService: any DeviceService,
        scenarioService: any ScenarioService,
    ) {
        self.sessionStore = sessionStore
        self.serverConfigStore = serverConfigStore
        self.registrationStore = registrationStore
        self.savedColorsStore = savedColorsStore
        self.toastStore = toastStore
        self.serverConfigService = serverConfigService
        self.deviceService = deviceService
        self.scenarioService = scenarioService
    }

    static func live() -> AppContainer {
        let tokenPersistence = KeychainAuthTokenPersistance()
        let serverConfigPersistence = UserDefaultsServerConfigPersistence()
        let registrationPersistence = UserDefaultsRegistrationPersistence()
        let savedColorsPersistence = UserDefaultsSavedColorsPersistence()

        let apiClient = HubAPIClient()

        let authService = HubAuthService(client: apiClient)
        let registrationService = HubRegistrationService(client: apiClient)
        let serverConfigService = HubServerConfigService(client: apiClient)
        let deviceService = HubDeviceService(client: apiClient)
        let scenarioService = HubScenarioService(client: apiClient)

        let sessionStore = SessionStore(service: authService, tokenPersistence: tokenPersistence)
        let serverConfigStore = ServerConfigStore(persistence: serverConfigPersistence, service: serverConfigService)
        let registrationStore = RegistrationStore(
            service: registrationService,
            persistence: registrationPersistence
        )
        let savedColorsStore = SavedColorsStore(persistence: savedColorsPersistence)

        apiClient.setServerProvider { serverConfigStore.selectedServer }
        apiClient.setTokenProvider { sessionStore.sessionToken }
        apiClient.setRefreshHandler { await sessionStore.refresh() }

        return AppContainer(
            sessionStore: sessionStore,
            serverConfigStore: serverConfigStore,
            registrationStore: registrationStore,
            savedColorsStore: savedColorsStore,
            toastStore: ToastStore(),
            serverConfigService: serverConfigService,
            deviceService: deviceService,
            scenarioService: scenarioService,
        )
    }

    static func preview() -> AppContainerPreviewBuilder {
        AppContainerPreviewBuilder()
    }

    // MARK: - Screen view models
    func buildLoginViewModel() -> LoginViewModel {
        LoginViewModel(sessionStore: sessionStore)
    }

    func buildRegisterViewModel() -> RegisterViewModel {
        RegisterViewModel(sessionStore: sessionStore, prefilledEmail: registrationStore.pendingRequest?.email ?? "")
    }

    func buildRegistrationRequestViewModel(email: String, comment: String) -> RegistrationRequestViewModel {
        RegistrationRequestViewModel(registrationStore: registrationStore, email: email, comment: comment)
    }

    func buildRegistrationStatusViewModel() -> RegistrationStatusViewModel {
        RegistrationStatusViewModel(registrationStore: registrationStore)
    }

    func buildServerSetupViewModel(mode: ServerSetupMode) -> ServerSetupViewModel {
        ServerSetupViewModel(mode: mode, store: serverConfigStore)
    }

    func buildDevicesViewModel() -> DevicesViewModel {
        DevicesViewModel(service: deviceService, toastStore: toastStore)
    }

    func buildDeviceDetailsViewModel(
        device: Device,
        onChanged: @escaping @MainActor (Device) -> Void,
        onDeleted: @escaping @MainActor (String) -> Void
    ) -> DeviceDetailViewModel {
        DeviceDetailViewModel(
            device: device,
            service: deviceService,
            toastStore: toastStore,
            onChanged: onChanged,
            onDeleted: onDeleted,
        )
    }

    func buildScenariosViewModel() -> ScenariosViewModel {
        ScenariosViewModel(service: scenarioService, deviceService: deviceService, toastStore: toastStore)
    }
}
