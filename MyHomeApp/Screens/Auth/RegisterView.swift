import SwiftUI

struct RegisterView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(RegistrationStore.self) private var registrationStore
    @State private var viewModel: RegisterViewModel?
    var onRegistered: () -> Void

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            if let viewModel {
                RegisterForm(viewModel: viewModel, onRegistered: onRegistered)
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = RegisterViewModel(
                    sessionStore: sessionStore,
                    email: registrationStore.pendingRequest?.email ?? ""
                )
            }
        }
    }
}

#Preview {
    let sessionStore = SessionStore(service: MockAuthService(operationDelay: .zero), tokenStore: InMemoryTokenStore())
    let request = RegistrationRequest(
        externalId: "abc",
        email: "new@home.dev",
        requesterComment: nil,
        status: .approved,
        role: .resident,
        blocked: false
    )
    let registrationStore = RegistrationStore(
        service: MockRegistrationService(operationDelay: .zero, status: .approved),
        persistence: InMemoryRegistrationPersistence(initial: request)
    )
    return NavigationStack {
        RegisterView(onRegistered: {})
            .environment(sessionStore)
            .environment(registrationStore)
    }
}
