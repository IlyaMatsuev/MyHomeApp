import SwiftUI

@main
struct SmartHomeAppIOSApp: App {
    private var sessionStore = SessionStore(service: MockAuthService(), tokenStore: KeychainTokenStore())
    private var serverConfigStore = ServerConfigStore(persistence: UserDefaultsServerConfigPersistence())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionStore)
                .environment(serverConfigStore)
        }
    }
}
