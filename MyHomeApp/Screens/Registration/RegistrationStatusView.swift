import SwiftUI

struct RegistrationStatusView: View {
    @Environment(RegistrationStore.self) private var registrationStore
    @State private var viewModel: RegistrationStatusViewModel?
    @State private var showCancelConfirmation = false
    var onDismiss: () -> Void

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
                viewModel?.cancel()
                onDismiss()
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
                actions(viewModel)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    private func badge(for status: RegistrationStatus) -> some View {
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
            Text(request.email)
                .font(.footnote.monospaced())
                .foregroundStyle(Color("TextSecondary"))
            Text(request.status.detail)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
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

    private func actions(_ viewModel: RegistrationStatusViewModel) -> some View {
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
}

#Preview("Pending") {
    let request = RegistrationRequest(externalId: "abc", email: "new@home.dev", status: .pending)
    let registrationStore = RegistrationStore(
        service: MockRegistrationService(operationDelay: .zero, status: .pending),
        persistence: InMemoryRegistrationPersistence(initial: request)
    )
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    let serverStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: [server]))
    return NavigationStack {
        RegistrationStatusView(onDismiss: {})
            .environment(registrationStore)
            .environment(serverStore)
    }
    .task { await serverStore.load() }
}

#Preview("Approved") {
    let request = RegistrationRequest(externalId: "abc", email: "new@home.dev", status: .approved)
    let registrationStore = RegistrationStore(
        service: MockRegistrationService(operationDelay: .zero, status: .approved),
        persistence: InMemoryRegistrationPersistence(initial: request)
    )
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    let serverStore = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: [server]))
    return NavigationStack {
        RegistrationStatusView(onDismiss: {})
            .environment(registrationStore)
            .environment(serverStore)
    }
    .task { await serverStore.load() }
}
