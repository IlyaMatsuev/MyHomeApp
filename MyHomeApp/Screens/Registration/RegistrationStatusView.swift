import SwiftUI

struct RegistrationStatusView: View {
    @Environment(RegistrationStore.self) private var registrationStore
    @State private var viewModel: RegistrationStatusViewModel?
    @State private var showCancelConfirmation = false
    var onDismiss: () -> Void
    var onRegister: () -> Void
    var onResubmit: () -> Void

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            if let viewModel {
                ScrollView {
                    content(viewModel)
                        .containerRelativeFrame(.vertical, alignment: .center)
                }
                .refreshable { await viewModel.refresh() }
            }
        }
        .navigationTitle("Access Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ServerSwitcherMenu()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Cancel access request?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel request", role: .destructive) {
                Task {
                    await viewModel?.cancel()
                    onDismiss()
                }
            }
            Button("Keep request", role: .cancel) {}
        } message: {
            Text("Your request to join this Home will be withdrawn. You can request access again later.")
        }
        .task {
            if viewModel == nil {
                viewModel = RegistrationStatusViewModel(registrationStore: registrationStore)
            }
            await viewModel?.refresh()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: RegistrationStatusViewModel) -> some View {
        if let request = viewModel.request {
            VStack(spacing: 24) {
                Spacer()
                badge(for: request.status)
                details(for: request)
                errorText(viewModel)
                Spacer()
                actions(viewModel, request: request)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    private func badge(for status: RegistrationRequestStatus) -> some View {
        VStack(spacing: 12) {
            Image(systemName: status.icon)
                .font(.system(size: 56))
                .foregroundStyle(status.color)
            Text(status.label)
                .font(.title2.bold())
                .foregroundStyle(Color("TextPrimary"))
        }
    }

    private func details(for request: RegistrationRequest) -> some View {
        VStack(spacing: 8) {
            if request.status == .approved {
                roleTile(request.role)
                    .padding(.top, 4)
            }

            Text(request.email)
                .font(.footnote.monospaced())
                .foregroundStyle(Color("TextSecondary"))

            if let comment = request.requesterComment, !comment.isEmpty {
                Text(comment)
                    .font(.footnote.italic())
                    .foregroundStyle(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }

            Text(request.status.explanation)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)

            if request.blocked {
                Text("You've been blocked from submitting new requests for this email.")
                    .font(.footnote)
                    .foregroundStyle(Color("Danger"))
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private func errorText(_ viewModel: RegistrationStatusViewModel) -> some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color("Danger"))
                .multilineTextAlignment(.center)
        }
    }

    private func roleTile(_ role: UserRole) -> some View {
        Text(role.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(role.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(role.color.opacity(0.15))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func actions(_ viewModel: RegistrationStatusViewModel, request: RegistrationRequest) -> some View {
        switch request.status {
        case .pending:
            cancelButton(viewModel)
        case .approved:
            createAccountButton
        case .rejected:
            if !request.blocked {
                resubmitButton
            }
        case .cancelled:
            resubmitButton
        }
    }

    private func cancelButton(_ viewModel: RegistrationStatusViewModel) -> some View {
        Button {
            showCancelConfirmation = true
        } label: {
            ZStack {
                Text("Cancel request")
                    .opacity(viewModel.cancelling ? 0 : 1)
                if viewModel.cancelling {
                    ProgressView().tint(Color("Danger"))
                }
            }
            .font(.headline)
            .foregroundStyle(Color("Danger"))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(viewModel.cancelling ? 0.5 : 1)
        }
        .disabled(viewModel.cancelling)
    }

    private var createAccountButton: some View {
        Button(action: onRegister) {
            Text("Create an account")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color("AccentPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var resubmitButton: some View {
        Button(action: onResubmit) {
            Text("Resubmit")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color("AccentPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview("Pending") {
    registrationStatusPreview(status: .pending)
}

#Preview("Approved") {
    registrationStatusPreview(status: .approved)
}

#Preview("Rejected") {
    registrationStatusPreview(status: .rejected)
}

@MainActor
private func registrationStatusPreview(status: RegistrationRequestStatus) -> some View {
    let request = RegistrationRequest(
        externalId: "abc",
        email: "new@home.dev",
        requesterComment: "Please let me in!",
        status: status,
        role: .resident,
        blocked: status == .rejected
    )
    let registrationStore = RegistrationStore(
        service: MockRegistrationService(operationDelay: .zero, status: status),
        persistence: InMemoryRegistrationPersistence(initial: request)
    )
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    let serverStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: [server]))
    return NavigationStack {
        RegistrationStatusView(onDismiss: {}, onRegister: {}, onResubmit: {})
            .environment(registrationStore)
            .environment(serverStore)
    }
    .task { await serverStore.load() }
}
