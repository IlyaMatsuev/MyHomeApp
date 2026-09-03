import SwiftUI

struct ServerSwitcherMenu: View {
    @Environment(ServerConfigStore.self) private var serverConfigStore

    @State private var showServerSetupScreen = false

    var body: some View {
        if !serverConfigStore.servers.isEmpty {
            Menu {
                Picker("Server", selection: selectionBinding) {
                    ForEach(serverConfigStore.servers) { server in
                        Label(server.label, systemImage: server.iconSystemName)
                            .tag(Optional(server.id))
                    }
                }
                Divider()
                Button("Edit", systemImage: "pencil") {
                    showServerSetupScreen = true
                }
            } label: {
                switcher
            }
            .accessibilityLabel("Switch server")
            .navigationDestination(isPresented: $showServerSetupScreen) {
                ServerSetupView(mode: .edit)
            }
        }
    }

    private var selectionBinding: Binding<String?> {
        Binding(
            get: { serverConfigStore.selectedServer?.id },
            set: { newId in
                let newServer = serverConfigStore.servers.first { $0.id == newId }
                serverConfigStore.select(newServer)
            }
        )
    }

    @ViewBuilder
    private var switcher: some View {
        HStack(spacing: 6) {
            Image(systemName: serverConfigStore.selectedServer?.iconSystemName ?? "server.rack")
            Text(serverConfigStore.selectedServer?.label ?? "Not selected")
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .foregroundStyle(Color("AccentPrimary"))
    }
}

#Preview {
    let server1 = Server(.http, "hub.local:8080", remote: false, label: "Home")
    let server2 = Server(.https, "hub.remote.com", remote: true, label: "Remote Home")
    return NavigationStack {
        Color("BackgroundPrimary").ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ServerSwitcherMenu()
                }
            }
    }
    .inject(AppContainer.preview().withServers([server1, server2]).build())
}
