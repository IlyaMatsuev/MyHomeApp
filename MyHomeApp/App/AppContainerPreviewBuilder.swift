@MainActor
class AppContainerPreviewBuilder {
    private var servers: [Server] = []

    func withServers(_ servers: [Server]) -> Self {
        self.servers = servers
        return self
    }

    func build() -> AppContainer {
        let authService = MockAuthService()
        let registrationService = MockRegistrationService()
        let serverConfigService = MockServerConfigService()
        let deviceService = MockDeviceService()
        let scenarioService = MockScenarioService()

        let sessionStore = SessionStore(service: authService, tokenPersistence: InMemoryAuthTokenPersistence())
        let serverConfigStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: servers))
        let registrationStore = RegistrationStore(
            service: registrationService,
            persistence: InMemoryRegistrationPersistence()
        )
        let savedColorsStore = SavedColorsStore(persistence: InMemorySavedColorsPersistence())

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
