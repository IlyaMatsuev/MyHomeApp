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
            VStack(spacing: 0) {
                header
                content(selectedGroup: $viewModel.selectedGroup)
                    .refreshable { await viewModel.refresh() }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
                    Task { await viewModel.confirmDeletion(of: scenario) }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDeletion()
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Scenarios")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))

            Spacer()

            Button {
                viewModel.startCreating()
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color("AccentPrimary"))
            }
            .accessibilityLabel("New scenario")
            .disabled(viewModel.state == .loading)
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func content(selectedGroup: Binding<ScenarioGroupFilter>) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            placeholder {
                ContentUnavailableView(
                    "Couldn't load scenarios",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }

        case .loaded:
            if viewModel.scenarios.isEmpty {
                placeholder { emptyState }
            } else {
                VStack(spacing: 0) {
                    FilterChipsBar(chips: groupChips, selection: selectedGroup)
                    ScenarioList(sections: viewModel.visibleSections).environment(viewModel)
                }
            }
        }
    }

    /// Keeps a full-screen placeholder pullable, so refreshing works when there is no list to pull.
    private func placeholder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
                .containerRelativeFrame(.vertical, alignment: .center)
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
