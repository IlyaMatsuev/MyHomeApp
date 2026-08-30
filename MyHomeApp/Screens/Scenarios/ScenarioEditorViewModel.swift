import Foundation
import Observation
import AnyCodable
import os

@Observable
@MainActor
final class ScenarioEditorViewModel: Identifiable {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "ScenarioEditorViewModel")

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
    let knownCommands: [ScenarioKnownCommand]

    /// Groups offered as pills. A name added here lives only in this editing session — the hub
    /// creates the group when the scenario itself is saved.
    private(set) var knownGroups: [String]

    var draft: ScenarioDraft

    private(set) var loading = false
    private(set) var errorMessage: String?

    /// Set by the first Save tap. Until then the editor only complains about fields the user has
    /// already overrun, so a half-typed form isn't covered in red.
    private(set) var didAttemptSave = false

    private let service: ScenarioService
    private let onSaved: @MainActor (Scenario) -> Void

    var canSave: Bool { !loading && draft.isValid }

    var validationMessage: String? { draft.structureError }

    /// `true` when the typed group is a valid name the pills don't offer yet.
    var canAddTypedGroup: Bool {
        let apiName = draft.groupApiName
        return ScenarioGroupName.isValid(apiName) && !knownGroups.contains(apiName)
    }

    var showsLogicEditor: Bool {
        draft.sources.count > 1 || draft.logicMode == .custom
    }

    var logicErrorMessage: String? {
        guard draft.logicMode == .custom, !draft.customLogic.isBlank else { return nil }
        guard !draft.logic.isValid(sourceCount: draft.sources.count) else { return nil }
        if !ScenarioLimits.logicLength.contains(draft.customLogic.trimmed.count) {
            return "Expression must be \(ScenarioLimits.logicLength.lowerBound)"
                + "–\(ScenarioLimits.logicLength.upperBound) characters."
        }
        return "Use each trigger number 1–\(max(draft.sources.count, 1)) exactly once, joined by AND or OR."
    }

    init(
        mode: Mode,
        draft: ScenarioDraft,
        devices: [Device],
        knownGroups: [String],
        knownCommands: [ScenarioKnownCommand],
        service: ScenarioService,
        onSaved: @escaping @MainActor (Scenario) -> Void
    ) {
        self.mode = mode
        self.draft = draft
        self.devices = devices
        self.knownGroups = knownGroups
        self.knownCommands = knownCommands
        self.service = service
        self.onSaved = onSaved
    }

    // MARK: - Field validation

    /// The message to show under a field, or `nil` while the editor should stay quiet about it.
    func error(for field: ScenarioTextField) -> String? {
        guard didAttemptSave || draft.exceedsLimit(field) else { return nil }
        return draft.error(for: field)
    }

    // MARK: - Groups

    /// Offers the typed group as a pill so it reads as chosen. Nothing is sent to the hub.
    func addTypedGroup() {
        guard canAddTypedGroup else { return }
        knownGroups = (knownGroups + [draft.groupApiName]).sorted()
    }

    // MARK: - Device lookups

    func device(withId deviceId: String) -> Device? {
        devices.first { $0.externalId == deviceId }
    }

    func toggleControlKeys(ofDeviceId deviceId: String) -> [String] {
        guard let controls = device(withId: deviceId)?.controls else { return [] }
        return controls
            .filter { $0.value.value is Bool }
            .keys
            .sorted()
    }

    func measurementKeys(ofDeviceId deviceId: String) -> [String] {
        guard let measurements = device(withId: deviceId)?.measurements else { return [] }
        return measurements.keys.sorted()
    }

    func knownCommand(ofDeviceId deviceId: String) -> ScenarioKnownCommand? {
        knownCommands.first { $0.deviceId == deviceId }
    }

    // MARK: - Trigger sources

    func addSource(kind: ScenarioTriggerSource.Kind) {
        var source = ScenarioSourceDraft(kind: kind)
        if kind == .device, let device = devices.first {
            source.deviceId = device.externalId
            applyMatchDefaults(to: &source)
        }
        draft.sources.append(source)
    }

    func removeSource(_ source: ScenarioSourceDraft) {
        draft.sources.removeAll { $0.id == source.id }
    }

    func selectDevice(_ deviceId: String, forSource source: ScenarioSourceDraft) {
        guard let index = draft.sources.firstIndex(where: { $0.id == source.id }) else { return }
        draft.sources[index].deviceId = deviceId
        applyMatchDefaults(to: &draft.sources[index])
    }

    func selectMatchKind(_ matchKind: ScenarioSourceDraft.MatchKind, forSource source: ScenarioSourceDraft) {
        guard let index = draft.sources.firstIndex(where: { $0.id == source.id }) else { return }
        draft.sources[index].matchKind = matchKind
        applyMatchDefaults(to: &draft.sources[index])
    }

    func selectMatchKey(_ matchKey: String, forSource source: ScenarioSourceDraft) {
        guard let index = draft.sources.firstIndex(where: { $0.id == source.id }) else { return }
        draft.sources[index].matchKey = matchKey
        applyMatchValue(to: &draft.sources[index])
    }

    private func applyMatchDefaults(to source: inout ScenarioSourceDraft) {
        switch source.matchKind {
        case .command:
            source.matchKey = knownCommand(ofDeviceId: source.deviceId)?.name ?? ScenarioSourceDraft.defaultCommandKey

        case .control:
            source.matchKey = toggleControlKeys(ofDeviceId: source.deviceId).first
                ?? ScenarioSourceDraft.defaultControlKey

        case .measurement:
            source.matchKey = measurementKeys(ofDeviceId: source.deviceId).first ?? ""
        }
        applyMatchValue(to: &source)
    }

    private func applyMatchValue(to source: inout ScenarioSourceDraft) {
        let matched = device(withId: source.deviceId)
        switch source.matchKind {
        case .command:
            source.matchText = knownCommand(ofDeviceId: source.deviceId)?.value ?? ""

        case .control:
            let controls = matched?.controls ?? [:]
            source.matchValue = controls[source.matchKey]?.value as? Bool ?? true

        case .measurement:
            let measurements = matched?.measurements ?? [:]
            source.matchText = measurements[source.matchKey].map(ScenarioSourceDraft.text(of:)) ?? ""
        }
    }

    // MARK: - Actions

    func addAction() {
        var action = ScenarioActionDraft()
        if let device = devices.first {
            action.deviceId = device.externalId
            action.controlKey = toggleControlKeys(ofDeviceId: device.externalId).first
                ?? ScenarioActionDraft.defaultControlKey
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
        didAttemptSave = true
        guard canSave else { return }

        errorMessage = nil
        loading = true
        defer { loading = false }

        do {
            let saved = try await persist(draft.payload)
            onSaved(saved)
        } catch {
            errorMessage = ScenarioError.text(for: error)
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
