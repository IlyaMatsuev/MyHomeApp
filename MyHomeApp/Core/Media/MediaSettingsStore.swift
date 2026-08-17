import Foundation
import Observation
import os

@Observable
@MainActor
final class MediaSettingsStore {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "MediaSettingsStore")

    private(set) var settings: MediaSettings = .disabled

    private let persistence: MediaSettingsPersistence

    /// Drives the visibility of the Media tab.
    var enabled: Bool {
        settings.active
    }

    /// The address the Media Manager requests are sent to, or `nil` when the integration is off.
    var server: Server? {
        settings.active ? settings.server : nil
    }

    init(persistence: MediaSettingsPersistence) {
        self.persistence = persistence
    }

    func load() async {
        do {
            settings = try persistence.load() ?? .disabled
        } catch {
            Self.logger.error("Failed to load the Media Manager settings: \(error.localizedDescription)")
            settings = .disabled
        }
    }

    func save(_ settings: MediaSettings) async throws {
        try persistence.save(settings)
        self.settings = settings
    }
}
