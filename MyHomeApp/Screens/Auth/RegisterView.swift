import SwiftUI

struct RegisterView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: RegisterViewModel?

    var onRegistered: () -> Void = {}

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
                viewModel = container.buildRegisterViewModel()
            }
        }
    }
}

#Preview {
    let request = RegistrationRequest(
        externalId: "abc",
        email: "new@home.dev",
        requesterComment: nil,
        status: .approved,
        role: .resident,
        blocked: false
    )
    return NavigationStack {
        RegisterView(onRegistered: {})
            .inject(AppContainer.preview().withRegistrationRequest(request).build())
    }
}
