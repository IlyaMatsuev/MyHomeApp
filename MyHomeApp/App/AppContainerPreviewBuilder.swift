@MainActor
class AppContainerPreviewBuilder {
    private var servers: [Server] = []
    private var savedColors: [SavedColor] = []
    private var registrationRequest: RegistrationRequest?
    private var registrationService: RegistrationService?

    func withServers(_ servers: [Server]) -> Self {
        self.servers = servers
        return self
    }

    func withSavedColors(_ colors: [SavedColor]) -> Self {
        self.savedColors = colors
        return self
    }

    func withRegistrationRequest(_ registrationRequest: RegistrationRequest) -> Self {
        self.registrationRequest = registrationRequest
        return self
    }

    func setRegistrationService(_ registrationService: RegistrationService) -> Self {
        self.registrationService = registrationService
        return self
    }

    func build() -> AppContainer {
        let authService = MockAuthService()
        let registrationService = registrationService ?? MockRegistrationService()
        let serverConfigService = MockServerConfigService()
        let deviceService = MockDeviceService()
        let scenarioService = MockScenarioService()

        let sessionStore = SessionStore(service: authService, tokenPersistence: InMemoryAuthTokenPersistence())
        let serverConfigStore = ServerConfigStore(
            persistence: InMemoryServerConfigPersistence(initial: servers),
            service: serverConfigService,
        )
        let registrationStore = RegistrationStore(
            service: registrationService,
            persistence: InMemoryRegistrationPersistence(initial: registrationRequest)
        )
        let savedColorsStore = SavedColorsStore(persistence: InMemorySavedColorsPersistence(initial: savedColors))

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
}
