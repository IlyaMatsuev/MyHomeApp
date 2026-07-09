import SwiftUI

struct SettingsView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack {
                Spacer()
                logoutButton
            }
            .padding(24)
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
    return SettingsView().environment(sessionStore)
}
