import Foundation
import Observation
import AnyCodable
import os

@Observable
@MainActor
final class DeviceDetailViewModel: Identifiable {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "DeviceDetailViewModel")

    let id = UUID()

    private(set) var device: Device

    /// Details are a form the user saves; controls and commands act on their own.
    var draft: DeviceDraft

    /// Pending control values, so a slider or text field can be dragged/typed before it is sent.
    private(set) var controlDrafts: [String: AnyCodable] = [:]
    private(set) var commandDrafts: [String: AnyCodable] = [:]

    private(set) var isSavingDetails = false
    private(set) var busyControlNames: Set<String> = []
    private(set) var busyCommandNames: Set<String> = []

    /// Commands the user has typed into or tried to send, so an untouched field isn't already red.
    private(set) var touchedCommandNames: Set<String> = []
    private(set) var isDeleting = false

    private(set) var detailsErrorMessage: String?

    /// Set by the first Save tap. Until then the form only complains about bounds the user has
    /// already overrun, so a half-typed field isn't covered in red.
    private(set) var didAttemptSave = false

    var isConfirmingDeletion = false

    private let service: DeviceService
    private let toastStore: ToastStore
    private let onChanged: @MainActor (Device) -> Void
    private let onDeleted: @MainActor (String) -> Void

    var controlItems: [DeviceConfigItem] { device.controlItems }
    var measurementItems: [DeviceConfigItem] { device.measurementItems }
    var commandItems: [DeviceConfigItem] { device.commandItems }

    var canSaveDetails: Bool { !isSavingDetails && !isDeleting && draft.isValid && hasDetailsChanges }

    var hasDetailsChanges: Bool { draft != DeviceDraft(device: device) }

    var isBusy: Bool {
        isSavingDetails || isDeleting || !busyControlNames.isEmpty || !busyCommandNames.isEmpty
    }

    init(
        device: Device,
        service: DeviceService,
        toastStore: ToastStore,
        onChanged: @escaping @MainActor (Device) -> Void,
        onDeleted: @escaping @MainActor (String) -> Void
    ) {
        self.device = device
        self.draft = DeviceDraft(device: device)
        self.service = service
        self.toastStore = toastStore
        self.onChanged = onChanged
        self.onDeleted = onDeleted
        seedControlDrafts()
        seedCommandDrafts()
    }

    // MARK: - Details

    /// The message to show under a field, or `nil` while the form should stay quiet about it.
    func detailsError(for field: DeviceField) -> String? {
        guard didAttemptSave || draft.exceedsLimit(field) else { return nil }
        return draft.error(for: field)
    }

    func saveDetails() async {
        didAttemptSave = true
        guard !isSavingDetails, draft.isValid else { return }

        detailsErrorMessage = nil
        isSavingDetails = true
        defer { isSavingDetails = false }

        do {
            let updated = try await service.updateDevice(deviceId: device.id, payload: draft.payload)
            apply(updated, resettingDetails: true)
        } catch {
            detailsErrorMessage = DeviceError.text(for: error)
            Self.logger.error("Failed to save details of \"\(self.device.id)\": \(error.localizedDescription)")
        }
    }

    func resetDetails() {
        draft = DeviceDraft(device: device)
        detailsErrorMessage = nil
        didAttemptSave = false
    }

    // MARK: - Controls

    func controlValue(of item: DeviceConfigItem) -> AnyCodable {
        controlDrafts[item.name] ?? item.fallbackValue
    }

    func setControlValue(_ value: AnyCodable, of item: DeviceConfigItem) {
        controlDrafts[item.name] = value
    }

    func controlError(of item: DeviceConfigItem) -> String? {
        DeviceConfigValue.error(for: item, value: controlDrafts[item.name])
    }

    func isBusyControl(_ item: DeviceConfigItem) -> Bool {
        busyControlNames.contains(item.name)
    }

    /// Whether the drafted value still differs from what the hub has stored.
    func isControlDirty(_ item: DeviceConfigItem) -> Bool {
        controlDrafts[item.name] != device.controlValue(of: item)
    }

    func commitControl(_ item: DeviceConfigItem) async {
        guard item.isEditable, isControlDirty(item), controlError(of: item) == nil else { return }
        guard let value = controlDrafts[item.name] else { return }

        busyControlNames.insert(item.name)
        defer { busyControlNames.remove(item.name) }

        do {
            let updated = try await service.updateControls(deviceId: device.id, controls: [item.name: value])
            apply(updated)
        } catch {
            seedControlDrafts()
            toastStore.error(DeviceError.text(for: error))
            Self.logger.error("Failed to update control \"\(item.name)\": \(error.localizedDescription)")
        }
    }

    // MARK: - Commands

    func commandValue(of item: DeviceConfigItem) -> AnyCodable {
        commandDrafts[item.name] ?? item.fallbackValue
    }

    func setCommandValue(_ value: AnyCodable, of item: DeviceConfigItem) {
        commandDrafts[item.name] = value
        touchedCommandNames.insert(item.name)
    }

    /// The message to show under a command, or `nil` while the form should stay quiet about it.
    func commandError(of item: DeviceConfigItem) -> String? {
        guard touchedCommandNames.contains(item.name) else { return nil }
        return commandValidationError(of: item)
    }

    private func commandValidationError(of item: DeviceConfigItem) -> String? {
        DeviceConfigValue.error(for: item, value: commandDrafts[item.name])
    }

    func isBusyCommand(_ item: DeviceConfigItem) -> Bool {
        busyCommandNames.contains(item.name)
    }

    func canSend(_ item: DeviceConfigItem) -> Bool {
        item.isEditable && !isBusyCommand(item) && commandValidationError(of: item) == nil
    }

    func sendCommand(_ item: DeviceConfigItem) async {
        touchedCommandNames.insert(item.name)
        guard canSend(item) else { return }
        let value = commandValue(of: item)

        busyCommandNames.insert(item.name)
        defer { busyCommandNames.remove(item.name) }

        do {
            let updated = try await service.sendCommand(deviceId: device.id, command: [item.name: value])
            apply(updated)
            toastStore.success("\(item.label) sent")
        } catch {
            toastStore.error(DeviceError.text(for: error))
            Self.logger.error("Failed to send command \"\(item.name)\": \(error.localizedDescription)")
        }
    }

    // MARK: - Deletion

    func requestDeletion() {
        isConfirmingDeletion = true
    }

    func cancelDeletion() {
        isConfirmingDeletion = false
    }

    func confirmDeletion() async {
        isConfirmingDeletion = false
        guard !isDeleting else { return }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await service.deleteDevice(deviceId: device.id)
            onDeleted(device.id)
        } catch {
            toastStore.error(DeviceError.text(for: error))
            Self.logger.error("Failed to delete \"\(self.device.id)\": \(error.localizedDescription)")
        }
    }

    // MARK: - Reconciling with the hub

    /// `resettingDetails` only after a details save — a control or command response must not throw
    /// away a name the user is still typing.
    private func apply(_ updated: Device, resettingDetails: Bool = false) {
        device = updated.preservingConfig(from: device)
        if resettingDetails {
            draft = DeviceDraft(device: device)
            didAttemptSave = false
        }
        seedControlDrafts()
        onChanged(device)
    }

    private func seedControlDrafts() {
        controlDrafts = Dictionary(
            uniqueKeysWithValues: controlItems.map { ($0.name, device.controlValue(of: $0) ?? $0.fallbackValue) }
        )
    }

    private func seedCommandDrafts() {
        commandDrafts = Dictionary(uniqueKeysWithValues: commandItems.map { ($0.name, $0.fallbackValue) })
    }
}
