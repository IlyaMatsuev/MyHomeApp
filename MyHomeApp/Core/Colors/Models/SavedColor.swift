import Foundation

/// A colour the user has kept for reuse across every device with a colour control.
///
/// The identity is local: the hub knows nothing about saved colors, it only ever receives `hex`.
struct SavedColor: Codable, Identifiable, Hashable {
    let id: UUID
    var hex: String

    init(id: UUID = UUID(), hex: String) {
        self.id = id
        self.hex = hex.normalizedHexColor ?? hex
    }
}
