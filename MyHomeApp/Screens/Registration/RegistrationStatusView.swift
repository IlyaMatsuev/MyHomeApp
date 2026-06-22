import SwiftUI

struct RegistrationStatusView: View {
    @Environment(RegistrationStore.self) private var registrationStore
    @State private var viewModel: RegistrationStatusViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()

                if let viewModel {
                    content(viewModel)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }

    private func badge(for status: RegistrationStatus) -> some View {
        VStack(spacing: 12) {
            Image(systemName: iconName(for: status))
                .font(.system(size: 56))
                .foregroundStyle(color(for: status))
            Text(status.label)
                .font(.title2.bold())
                .foregroundStyle(Color("TextPrimary"))
        }
    }

    private func details(for request: RegistrationRequest) -> some View {
        VStack(spacing: 8) {
            Text(request.status.detail)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.center)
            Text(request.email)
                .font(.footnote.monospaced())
                .foregroundStyle(Color("TextSecondary"))
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
        VStack(spacing: 12) {
            Button {
                Task { await viewModel.refresh() }
            } label: {
                ZStack {
                    Text("Refresh status")
                        .opacity(viewModel.refreshing ? 0 : 1)
                    if viewModel.refreshing {
                        ProgressView().tint(.white)
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color("AccentPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(viewModel.refreshing ? 0.5 : 1)
            }
            .disabled(viewModel.refreshing)

            Button("Back to login") {
                viewModel.backToLogin()
            }
            .font(.footnote)
            .foregroundStyle(Color("AccentPrimary"))
        }
    }

    private func iconName(for status: RegistrationStatus) -> String {
        switch status {
        case .pending: "clock.badge.questionmark"
        case .approved: "checkmark.seal.fill"
        case .rejected: "xmark.seal.fill"
        }
    }

    private func color(for status: RegistrationStatus) -> Color {
        switch status {
        case .pending: Color("Warning")
        case .approved: Color("Success")
        case .rejected: Color("Danger")
        }
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
    return RegistrationStatusView()
        .environment(registrationStore)
        .environment(serverStore)
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
    return RegistrationStatusView()
        .environment(registrationStore)
        .environment(serverStore)
        .task { await serverStore.load() }
}
