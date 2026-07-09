import SwiftUI

struct LoginForm: View {
    @Bindable var viewModel: LoginViewModel
    var hasPendingRequest: Bool
    var onRequestAccess: () -> Void
    var onOpenRequest: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            header
            fields
            errorText
            actions
        }
        .padding(.horizontal, 24)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Some cool image")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("TextPrimary"))
            Text("Sign in to your home")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            EmailField(email: $viewModel.email, invalidEmail: viewModel.showEmailError)
            PasswordField(password: $viewModel.password)
        }
    }

    @ViewBuilder
    private var errorText: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                Task { await viewModel.submit() }
            } label: {
                loginLabel
            }
            .disabled(!viewModel.canSubmit)

            if hasPendingRequest {
                pendingRequestTile
            }

            Button("No account yet?") {
                onRequestAccess()
            }
            .font(.footnote)
            .foregroundStyle(Color("AccentPrimary"))
        }
    }

    private var pendingRequestTile: some View {
        Button(action: onOpenRequest) {
            HStack(spacing: 8) {
                Text("My request")
                Image(systemName: "arrow.right")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("AccentPrimary"))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color("AccentPrimary").opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var loginLabel: some View {
        ZStack {
            Text("Login")
                .opacity(viewModel.loading ? 0 : 1)
            if viewModel.loading {
                ProgressView().tint(.white)
            }
        }
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(Color("AccentPrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(viewModel.canSubmit ? 1 : 0.5)
    }
}
