import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(RegistrationStore.self) private var registrationStore
    @State private var viewModel: LoginViewModel?
    @State private var path: [Route] = []

    private enum Route: Hashable {
        case newRegistrationRequest(email: String, comment: String)
        case registrationRequestStatus
        case register
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()

                if let viewModel {
                    LoginForm(
                        viewModel: viewModel,
                        hasPendingRequest: registrationStore.hasPendingRequest,
                        onRequestAccess: { path.append(.newRegistrationRequest(email: "", comment: "")) },
                        onOpenRequest: { path.append(.registrationRequestStatus) }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ServerSwitcherMenu()
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .newRegistrationRequest(let email, let comment):
                    RegistrationRequestView(
                        email: email,
                        comment: comment,
                        onSubmitted: { path = [.registrationRequestStatus] },
                        onAlreadyApproved: { path.append(.register) }
                    )
                case .registrationRequestStatus:
                    RegistrationStatusView(
                        onDismiss: { path.removeAll() },
                        onRegister: { path.append(.register) },
                        onResubmit: {
                            let email = registrationStore.pendingRequest?.email ?? ""
                            let comment = registrationStore.pendingRequest?.requesterComment ?? ""
                            path.append(.newRegistrationRequest(email: email, comment: comment))
                        }
                    )
                case .register:
                    RegisterView(onRegistered: {
                        let email = registrationStore.pendingRequest?.email ?? ""
                        registrationStore.clear()
                        path.removeAll()
                        viewModel?.email = email
                    })
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = LoginViewModel(sessionStore: sessionStore)
            }
        }
    }
}

#Preview {
    let sessionStore = SessionStore(service: MockAuthService(operationDelay: .zero), tokenStore: InMemoryTokenStore())
    let registrationStore = RegistrationStore(
        service: MockRegistrationService(operationDelay: .zero),
        persistence: InMemoryRegistrationPersistence()
    )
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    let serverStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: [server]))
    return LoginView()
        .environment(sessionStore)
        .environment(registrationStore)
        .environment(serverStore)
        .task { await serverStore.load() }
}
