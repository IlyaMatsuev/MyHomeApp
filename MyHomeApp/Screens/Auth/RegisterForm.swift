import SwiftUI

struct RegisterForm: View {
    @Bindable var viewModel: RegisterViewModel
    var onRegistered: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            header
            fields
            errorText
            registerButton
        }
        .padding(.horizontal, 24)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Create your account")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("TextPrimary"))
            Text("Set a password to finish setting up your account.")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            EmailField(email: $viewModel.email, invalidEmail: viewModel.showEmailError)
            PasswordField(password: $viewModel.password)
            PasswordField(password: $viewModel.confirmPassword, title: "Confirm password")

            if viewModel.showPasswordMismatch {
                Text("Passwords don't match")
                    .font(.caption2)
                    .foregroundStyle(Color("Danger"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private var errorText: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color("Danger"))
                .multilineTextAlignment(.center)
        }
    }

    private var registerButton: some View {
        Button {
            Task {
                if await viewModel.register() {
                    onRegistered()
                }
            }
        } label: {
            ZStack {
                Text("Register")
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
        .disabled(!viewModel.canSubmit)
    }
}
