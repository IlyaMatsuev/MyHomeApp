import SwiftUI

struct SettingsView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(MediaSettingsStore.self) private var mediaSettingsStore
    @Environment(\.mediaService) private var mediaService

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    ScrollView {
                        VStack(spacing: 16) {
                            MediaManagerSection(store: mediaSettingsStore, service: mediaService)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)

                    logoutButton
                }
                .padding(24)
            }
            .navigationTitle("Settings")
        }
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            sessionStore.logout()
        } label: {
            Text("Log out")
                .font(.headline)
                .foregroundStyle(Color("Danger"))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    let sessionStore = SessionStore(service: MockAuthService(), tokenStore: InMemoryTokenStore())
    let mediaSettingsStore = MediaSettingsStore(persistence: InMemoryMediaSettingsPersistence())
    return SettingsView()
        .environment(sessionStore)
        .environment(mediaSettingsStore)
        .environment(\.mediaService, MockMediaService(operationDelay: .milliseconds(300)))
}
