import SwiftUI

struct DevicesScreen: View {
    @Bindable var viewModel: DevicesViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Devices")
                .background(Color("BackgroundPrimary").ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { ServerSwitcherMenu() }
                }
                .sheet(item: $viewModel.detail) { DeviceDetailSheet(viewModel: $0) }
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
                    DeviceList(roomGroups: viewModel.visibleRoomGroups)
                        .environment(viewModel)
                        .refreshable { await viewModel.refresh() }
                }
            }
        }
    }
}
