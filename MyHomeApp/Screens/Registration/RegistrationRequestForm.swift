import SwiftUI

struct RegistrationRequestForm: View {
    @Bindable var viewModel: RegistrationRequestViewModel
    var onSubmitted: () -> Void
    var onAlreadyApproved: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            header
            fields
            errorText
            actions
        }
        .padding(.horizontal, 24)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            requestButton
            alreadyApprovedButton
        }
    }

    private var alreadyApprovedButton: some View {
        Button(action: onAlreadyApproved) {
            Text("Already approved")
                .font(.headline)
                .foregroundStyle(Color("AccentPrimary"))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            EmailField(email: $viewModel.email, invalidEmail: viewModel.showEmailError)
            commentField
        }
    }

    private var commentField: some View {
        TextField("Comment (optional)", text: $viewModel.comment, axis: .vertical)
            .lineLimit(3...6)
            .padding()
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Join this home")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("TextPrimary"))
            Text("Enter your email and we'll send your request to the Home admin for approval")
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
            Task {
                if await viewModel.submit() {
                    onSubmitted()
                }
            }
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
