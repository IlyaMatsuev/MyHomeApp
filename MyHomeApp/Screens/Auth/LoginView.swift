import SwiftUI

struct LoginView: View {
    @Environment(AppContainer.self) private var container
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
                        hasPendingRequest: container.registrationStore.hasPendingRequest,
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
                            let email = container.registrationStore.pendingRequest?.email ?? ""
                            let comment = container.registrationStore.pendingRequest?.requesterComment ?? ""
                            path.append(.newRegistrationRequest(email: email, comment: comment))
                        }
                    )
                case .register:
                    RegisterView(onRegistered: {
                        let email = container.registrationStore.pendingRequest?.email ?? ""
                        container.registrationStore.clear()
                        path.removeAll()
                        viewModel?.email = email
                    })
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = container.buildLoginViewModel()
            }
        }
    }
}

#Preview {
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    return LoginView()
        .inject(AppContainer.preview().withServers([server]).build())
}
