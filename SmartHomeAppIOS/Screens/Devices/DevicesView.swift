import SwiftUI

struct DevicesView: View {
    @State private var viewModel: DevicesViewModel

    init(service: any DeviceService, toastStore: ToastStore) {
        self._viewModel = State(initialValue: DevicesViewModel(service: service, toastStore: toastStore))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Devices")
                .background(Color("BackgroundPrimary").ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ServerSwitcherMenu()
                    }
                }
                .task {
                    if viewModel.state == .idle {
                        await viewModel.load()
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            ContentUnavailableView(
                "Couldn't load devices",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

        case .loaded:
            if viewModel.roomGroups.isEmpty {
                ContentUnavailableView(
                    "No devices",
                    systemImage: "dot.radiowaves.left.and.right",
                    description: Text("Devices added to your hub will appear here.")
                )
            } else {
                VStack(spacing: 0) {
                    DeviceRoomFilterList(availableRooms: viewModel.availableRooms, selection: $viewModel.selectedRoom)
                    DeviceList(roomGroups: viewModel.visibleRoomGroups).environment(viewModel)
                }
            }
        }
    }
}

#Preview {
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    let store = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: [server]))
    return DevicesView(service: MockDeviceService(), toastStore: ToastStore())
        .environment(store)
        .task { await store.load() }
}
