import Foundation
import Observation
import os

struct ScenarioGroupSection: Identifiable, Hashable {
    /// `nil` for the scenarios the hub returned without a group.
    let group: String?
    let scenarios: [Scenario]

    var id: String { group ?? "" }
    var title: String { ScenarioGroupName.label(for: group) }
}

extension ScenarioGroupSection: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        // Ungrouped scenarios sit at the top, the named groups follow alphabetically.
        switch (lhs.group, rhs.group) {
        case (nil, nil): return false
        case (nil, _): return true
        case (_, nil): return false
        case (let lhsGroup?, let rhsGroup?):
            return lhsGroup.localizedCaseInsensitiveCompare(rhsGroup) == .orderedAscending
        }
    }
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
        Dictionary(grouping: scenarios, by: \.group)
            .map { ScenarioGroupSection(group: $0, scenarios: $1.sorted()) }
            .sorted()
    }

    /// Chips for the filter bar — the groups actually present in the loaded scenarios.
    var groupFilters: [ScenarioGroupFilter] {
        [.all] + groupSections.map { ScenarioGroupFilter(group: $0.group) }
    }

    /// Group names to suggest in the editor. The hub creates a group implicitly, so this is
    /// a convenience rather than a closed list.
    var knownGroups: [String] {
        groupSections.compactMap(\.group)
    }

    var visibleSections: [ScenarioGroupSection] {
        groupSections.filter { selectedGroup.matches(group: $0.group) }
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
            state = .failed(ScenarioError.text(for: error))
            toastStore.error(ScenarioError.text(for: error))
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
            toastStore.error(ScenarioError.text(for: error))
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
            toastStore.error(ScenarioError.text(for: error))
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
            knownGroups: knownGroups,
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
