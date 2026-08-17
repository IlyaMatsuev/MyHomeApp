import Foundation
import Observation
import AnyCodable
import os

/// One editing session — creating a new scenario or updating an existing one.
///
/// Presented via `.sheet(item:)`, hence `Identifiable`: a fresh instance means a fresh sheet.
@Observable
@MainActor
final class ScenarioEditorViewModel: Identifiable {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "ScenarioEditorViewModel")
    private static let incompleteDraftError = "Give the scenario a name, at least one trigger and one action."

    enum Mode: Hashable {
        case create
        case edit(String)

        var title: String {
            switch self {
            case .create: return "New Scenario"
            case .edit: return "Edit Scenario"
            }
        }
    }

    let id = UUID()
    let mode: Mode
    let devices: [Device]
    let knownGroups: [ScenarioGroup]

    var draft: ScenarioDraft

    private(set) var loading = false
    private(set) var errorMessage: String?

    private let service: ScenarioService
    private let onSaved: @MainActor (Scenario) -> Void

    var canSave: Bool { !loading && draft.isValid }

    /// Combining triggers only means something past the first one — but a custom expression must stay
    /// reachable whatever the source count, otherwise deleting sources can strand an expression that
    /// blocks saving with no way to edit it.
    var showsLogicEditor: Bool {
        draft.sources.count > 1 || draft.logicMode == .custom
    }

    /// Inline complaint about the custom expression, shown under the logic field.
    var logicErrorMessage: String? {
        guard draft.logicMode == .custom, !draft.customLogic.isBlank else { return nil }
        guard !draft.logic.isValid(sourceCount: draft.sources.count) else { return nil }
        return "Use trigger numbers 1–\(max(draft.sources.count, 1)) with AND, OR, NOT and parentheses."
    }

    init(
        mode: Mode,
        draft: ScenarioDraft,
        devices: [Device],
        knownGroups: [ScenarioGroup],
        service: ScenarioService,
        onSaved: @escaping @MainActor (Scenario) -> Void
    ) {
        self.mode = mode
        self.draft = draft
        self.devices = devices
        self.knownGroups = knownGroups
        self.service = service
        self.onSaved = onSaved
    }

    // MARK: - Device lookups

    func device(withId deviceId: String) -> Device? {
        devices.first { $0.externalId == deviceId }
    }

    /// Control keys of a device the app knows how to set — today that means booleans only.
    func toggleControlKeys(ofDeviceId deviceId: String) -> [String] {
        guard let controls = device(withId: deviceId)?.controls else { return [] }
        return controls
            .filter { $0.value.value is Bool }
            .keys
            .sorted()
    }

    // MARK: - Trigger sources

    func addSource(kind: ScenarioTriggerSource.Kind) {
        var source = ScenarioSourceDraft(kind: kind)
        if kind == .device, let device = devices.first {
            source.deviceId = device.externalId
            source.matchKey = toggleControlKeys(ofDeviceId: device.externalId).first ?? ScenarioSourceDraft.defaultControlKey
        }
        draft.sources.append(source)
    }

    func removeSource(_ source: ScenarioSourceDraft) {
        draft.sources.removeAll { $0.id == source.id }
    }

    func selectDevice(_ deviceId: String, forSource source: ScenarioSourceDraft) {
        guard let index = draft.sources.firstIndex(where: { $0.id == source.id }) else { return }
        draft.sources[index].deviceId = deviceId
        if draft.sources[index].matchKind == .control {
            draft.sources[index].matchKey = toggleControlKeys(ofDeviceId: deviceId).first
                ?? ScenarioSourceDraft.defaultControlKey
        }
    }

    func selectMatchKind(_ matchKind: ScenarioSourceDraft.MatchKind, forSource source: ScenarioSourceDraft) {
        guard let index = draft.sources.firstIndex(where: { $0.id == source.id }) else { return }
        draft.sources[index].matchKind = matchKind
        switch matchKind {
        case .command:
            draft.sources[index].matchKey = ScenarioSourceDraft.defaultCommandKey

        case .control:
            draft.sources[index].matchKey = toggleControlKeys(ofDeviceId: draft.sources[index].deviceId).first
                ?? ScenarioSourceDraft.defaultControlKey
        }
    }

    // MARK: - Actions

    func addAction() {
        var action = ScenarioActionDraft()
        if let device = devices.first {
            action.deviceId = device.externalId
            action.controlKey = toggleControlKeys(ofDeviceId: device.externalId).first ?? ScenarioActionDraft.defaultControlKey
        }
        draft.actions.append(action)
    }

    func removeAction(_ action: ScenarioActionDraft) {
        draft.actions.removeAll { $0.id == action.id }
    }

    func selectDevice(_ deviceId: String, forAction action: ScenarioActionDraft) {
        guard let index = draft.actions.firstIndex(where: { $0.id == action.id }) else { return }
        draft.actions[index].deviceId = deviceId
        draft.actions[index].controlKey = toggleControlKeys(ofDeviceId: deviceId).first
            ?? ScenarioActionDraft.defaultControlKey
    }

    // MARK: - Saving

    func save() async {
        guard canSave else {
            errorMessage = Self.incompleteDraftError
            return
        }

        errorMessage = nil
        loading = true
        defer { loading = false }

        do {
            let saved = try await persist(draft.payload)
            onSaved(saved)
        } catch {
            errorMessage = ScenarioErrorMessage.text(for: error)
            Self.logger.error("Failed to save a scenario: \(error.localizedDescription)")
        }
    }

    private func persist(_ payload: ScenarioPayload) async throws -> Scenario {
        switch mode {
        case .create:
            return try await service.createScenario(payload: payload)

        case .edit(let scenarioId):
            return try await service.updateScenario(scenarioId: scenarioId, payload: payload)
        }
    }
}
