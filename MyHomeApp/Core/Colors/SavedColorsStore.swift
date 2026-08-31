import Foundation
import Observation
import os

/// The colours the user has saved, shared by every device whose config declares a colour control.
///
/// Saved colors are a local convenience, so a persistence failure is logged rather than surfaced —
/// the list still works for the rest of the session.
@Observable
@MainActor
final class SavedColorsStore {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "SavedColorsStore")

    private(set) var colors: [SavedColor] = []

    private let persistence: SavedColorsPersistence

    init(persistence: SavedColorsPersistence) {
        self.persistence = persistence
        do {
            colors = try persistence.load()
        } catch {
            Self.logger.error("Failed to load saved colors: \(error.localizedDescription)")
        }
    }

    func contains(_ hex: String) -> Bool {
        guard let normalized = hex.normalizedHexColor else { return false }
        return colors.contains { $0.hex == normalized }
    }

    /// Ignores anything that isn't a hex colour, and anything already saved.
    func add(_ hex: String) {
        guard let normalized = hex.normalizedHexColor, !contains(normalized) else { return }
        colors.append(SavedColor(hex: normalized))
        persist()
    }

    func update(_ color: SavedColor, to hex: String) {
        guard let normalized = hex.normalizedHexColor,
              let index = colors.firstIndex(where: { $0.id == color.id }) else { return }
        guard !colors.contains(where: { $0.id != color.id && $0.hex == normalized }) else {
            remove(color)
            return
        }
        colors[index].hex = normalized
        persist()
    }

    func remove(_ color: SavedColor) {
        colors.removeAll { $0.id == color.id }
        persist()
    }

    private func persist() {
        do {
            try persistence.save(colors)
        } catch {
            Self.logger.error("Failed to save saved colors: \(error.localizedDescription)")
        }
    }
}
