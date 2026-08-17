import Foundation
import Observation
import os

struct ScenarioGroupSection: Identifiable, Hashable {
    let group: ScenarioGroup
    let scenarios: [Scenario]

    var id: String { group.rawValue }
    var title: String { group.label }
}

@Observable
@MainActor
final class ScenariosViewModel {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "ScenariosViewModel")

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var selectedGroup: ScenarioGroupFilter

    private(set) var state: LoadState = .idle
    private(set) var scenarios: [Scenario] = []
    private(set) var devices: [Device] = []
    private(set) var busyScenarioIds: Set<String> = []

    /// Drives the editor sheet — non-nil while creating or editing.
    var editor: ScenarioEditorViewModel?
    /// Drives the delete confirmation dialog.
    var scenarioPendingDeletion: Scenario?

    private let service: ScenarioService
    private let deviceService: DeviceService
    private let toastStore: ToastStore

    var groupSections: [ScenarioGroupSection] {
        Dictionary(grouping: scenarios, by: { $0.displayGroup })
            .map { ScenarioGroupSection(group: $0, scenarios: $1.sorted()) }
            .sorted(using: KeyPathComparator(\.group))
    }

    var availableGroups: [ScenarioGroup] { groupSections.map(\.group) }

    var visibleSections: [ScenarioGroupSection] {
        switch selectedGroup {
        case .all:
            groupSections

        case .specific(let group):
            groupSections.filter { $0.group == group }
        }
    }

    init(
        service: ScenarioService,
        deviceService: DeviceService,
        toastStore: ToastStore,
        selectedGroup: ScenarioGroupFilter = .all
    ) {
        self.service = service
        self.deviceService = deviceService
        self.toastStore = toastStore
        self.selectedGroup = selectedGroup
    }

    // MARK: - Loading

    func load() async {
        state = .loading

        // Devices only feed the editor's pickers, so their failure must not fail the screen.
        async let devicesPage = deviceService.fetchDevices()

        do {
            let page = try await service.fetchScenarios()
            scenarios = page.items.sorted()
            state = .loaded
        } catch {
            scenarios = []
            state = .failed(error.localizedDescription)
            toastStore.error(ScenarioErrorMessage.text(for: error))
        }

        do {
            let page = try await devicesPage
            devices = page.items.sorted()
        } catch {
            devices = []
            Self.logger.error("Failed to load devices for the scenario editor: \(error.localizedDescription)")
        }
    }

    func isBusy(_ scenario: Scenario) -> Bool {
        busyScenarioIds.contains(scenario.id)
    }

    // MARK: - Active toggle

    func setActive(_ scenario: Scenario, to newValue: Bool) async {
        let previous = scenario

        busyScenarioIds.insert(scenario.id)
        var optimistic = scenario
        optimistic.active = newValue
        replace(optimistic)

        do {
            let updated = try await service.setActive(scenarioId: scenario.id, active: newValue)
            replace(updated)
        } catch {
            replace(previous)
            toastStore.error(ScenarioErrorMessage.text(for: error))
            Self.logger.error("Failed to toggle scenario \"\(scenario.id)\": \(error.localizedDescription)")
        }

        busyScenarioIds.remove(scenario.id)
    }

    // MARK: - Deletion

    func requestDeletion(of scenario: Scenario) {
        scenarioPendingDeletion = scenario
    }

    func cancelDeletion() {
        scenarioPendingDeletion = nil
    }

    func confirmDeletion() async {
        guard let scenario = scenarioPendingDeletion else { return }
        scenarioPendingDeletion = nil
        await delete(scenario)
    }

    private func delete(_ scenario: Scenario) async {
        busyScenarioIds.insert(scenario.id)

        do {
            try await service.deleteScenario(scenarioId: scenario.id)
            scenarios.removeAll { $0.id == scenario.id }
        } catch {
            toastStore.error(ScenarioErrorMessage.text(for: error))
            Self.logger.error("Failed to delete scenario \"\(scenario.id)\": \(error.localizedDescription)")
        }

        busyScenarioIds.remove(scenario.id)
    }

    // MARK: - Editing

    func startCreating() {
        editor = makeEditor(mode: .create, draft: ScenarioDraft())
    }

    func startEditing(_ scenario: Scenario) {
        editor = makeEditor(mode: .edit(scenario.id), draft: ScenarioDraft(scenario: scenario))
    }

    func closeEditor() {
        editor = nil
    }

    private func makeEditor(mode: ScenarioEditorViewModel.Mode, draft: ScenarioDraft) -> ScenarioEditorViewModel {
        ScenarioEditorViewModel(
            mode: mode,
            draft: draft,
            devices: devices,
            knownGroups: availableGroups,
            service: service
        ) { [weak self] saved in
            self?.merge(saved)
            self?.closeEditor()
        }
    }

    private func merge(_ scenario: Scenario) {
        if let index = scenarios.firstIndex(where: { $0.id == scenario.id }) {
            scenarios[index] = scenario
        } else {
            scenarios.append(scenario)
        }
        scenarios.sort()
    }

    private func replace(_ scenario: Scenario) {
        guard let index = scenarios.firstIndex(where: { $0.id == scenario.id }) else { return }
        scenarios[index] = scenario
    }
}
