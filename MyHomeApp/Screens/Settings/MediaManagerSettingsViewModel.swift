import Foundation
import Observation
import os

@Observable
@MainActor
final class MediaManagerSettingsViewModel {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "MediaManagerSettingsViewModel")
    private static let addressRequiredError = "Enter the Media Manager address. Example: 192.168.1.10:8080"
    private static let unreachableError = "Couldn't reach the Media Manager at this address."
    private static let saveFailedError = "Couldn't save the Media Manager settings."

    var draft: MediaSettings {
        didSet { errorMessage = nil }
    }

    private(set) var errorMessage: String?
    private(set) var saving = false

    private let store: MediaSettingsStore
    private let service: any MediaService

    var canSave: Bool {
        !saving && (!draft.enabled || draft.valid)
    }

    init(store: MediaSettingsStore, service: any MediaService) {
        self.store = store
        self.service = service
        self.draft = store.settings
    }

    func save() async {
        guard !saving else { return }

        errorMessage = nil

        var settings = draft
        settings.server.address = settings.server.address.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !settings.enabled || settings.valid else {
            errorMessage = Self.addressRequiredError
            return
        }

        saving = true
        defer { saving = false }

        if settings.enabled {
            let healthy = await service.isHealthy(server: settings.server)
            guard healthy else {
                errorMessage = Self.unreachableError
                return
            }
        }

        do {
            try await store.save(settings)
            draft = settings
        } catch {
            Self.logger.error("Failed to save the Media Manager settings: \(error.localizedDescription)")
            errorMessage = Self.saveFailedError
        }
    }
}
