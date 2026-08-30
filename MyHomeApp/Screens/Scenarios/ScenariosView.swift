import SwiftUI

struct ScenariosView: View {
    @State private var viewModel: ScenariosViewModel

    init(service: any ScenarioService, deviceService: any DeviceService, toastStore: ToastStore) {
        self._viewModel = State(
            initialValue: ScenariosViewModel(
                service: service,
                deviceService: deviceService,
                toastStore: toastStore
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        return NavigationStack {
            content(selectedGroup: $viewModel.selectedGroup)
                .navigationTitle("Scenarios")
                .background(Color("BackgroundPrimary").ignoresSafeArea())
                .toolbar { toolbarContent }
                .task {
                    if viewModel.state == .idle {
                        await viewModel.load()
                    }
                }
                .sheet(item: $viewModel.editor) { editor in
                    ScenarioEditorSheet(viewModel: editor)
                }
                .confirmationDialog(
                    "Delete this scenario?",
                    isPresented: isDeletionConfirmed,
                    titleVisibility: .visible,
                    presenting: viewModel.scenarioPendingDeletion
                ) { scenario in
                    Button("Delete \"\(scenario.name)\"", role: .destructive) {
                        Task { await viewModel.confirmDeletion() }
                    }
                    Button("Cancel", role: .cancel) {
                        viewModel.cancelDeletion()
                    }
                }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            ServerSwitcherMenu()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.startCreating()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("New scenario")
            .disabled(viewModel.state == .loading)
        }
    }

    @ViewBuilder
    private func content(selectedGroup: Binding<ScenarioGroupFilter>) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            ContentUnavailableView(
                "Couldn't load scenarios",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

        case .loaded:
            if viewModel.scenarios.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    FilterChipsBar(chips: groupChips, selection: selectedGroup)
                    ScenarioList(sections: viewModel.visibleSections).environment(viewModel)
                }
            }
        }
    }

    private var groupChips: [FilterChipsBar<ScenarioGroupFilter>.Chip] {
        viewModel.groupFilters.map { .init($0, label: $0.label) }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No scenarios", systemImage: "wand.and.stars")
        } description: {
            Text("Scenarios react to a schedule or to your devices. Create one to get started.")
        } actions: {
            Button("New Scenario") { viewModel.startCreating() }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentPrimary"))
        }
    }

    private var isDeletionConfirmed: Binding<Bool> {
        Binding(
            get: { viewModel.scenarioPendingDeletion != nil },
            set: { presented in
                if !presented {
                    viewModel.cancelDeletion()
                }
            }
        )
    }
}

#Preview {
    let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
    let store = ServerConfigStore(persistence: InMemoryServerConfigPersistence(initial: [server]))
    return ScenariosView(
        service: MockScenarioService(),
        deviceService: MockDeviceService(),
        toastStore: ToastStore()
    )
    .environment(store)
    .task { await store.load() }
}
