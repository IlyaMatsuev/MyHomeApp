import SwiftUI

struct ContentView: View {
    @Environment(\.deviceService) private var deviceService
    @Environment(\.mediaService) private var mediaService
    @Environment(MediaSettingsStore.self) private var mediaSettingsStore
    @Environment(ToastStore.self) private var toastStore

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            TabView {
                DevicesView(service: deviceService, toastStore: toastStore)
                    .tabItem {
                        Label("Devices", systemImage: "lightbulb.fill")
                    }
                if mediaSettingsStore.enabled {
                    MediaView(service: mediaService, toastStore: toastStore)
                        .tabItem {
                            Label("Media", systemImage: "film.fill")
                        }
                }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(Color("AccentPrimary"))
        }
    }
}

#Preview {
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    let serverConfigStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: [server]))
    let sessionStore = SessionStore(service: MockAuthService(), tokenStore: InMemoryTokenStore())
    let mediaSettings = MediaSettings(enabled: true, server: Server(.http, "media.home:8080", label: "Media Manager"))
    let mediaSettingsStore = MediaSettingsStore(persistence: InMemoryMediaSettingsPersistence(initial: mediaSettings))
    return ContentView()
        .environment(sessionStore)
        .environment(serverConfigStore)
        .environment(mediaSettingsStore)
        .environment(ToastStore())
        .task {
            await serverConfigStore.load()
            await mediaSettingsStore.load()
        }
}
