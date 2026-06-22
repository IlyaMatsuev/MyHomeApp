import SwiftUI

struct RegistrationRequestForm: View {
    @Bindable var viewModel: RegistrationRequestViewModel

    var body: some View {
        VStack(spacing: 24) {
            header
            EmailField(email: $viewModel.email, invalidEmail: viewModel.showEmailError)
            errorText
            requestButton
        }
        .padding(.horizontal, 24)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Join this home")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("TextPrimary"))
            Text("Enter your email and we'll send your request to the hub owner for approval.")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
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

    private var requestButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            ZStack {
                Text("Request access")
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
