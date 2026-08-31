/// A colour the user has kept for reuse across every device with a colour control.
///
/// The hex *is* the identity: `SavedColorsStore` normalizes it and refuses duplicates, so no two
/// saved colours can share one. The hub knows nothing about them — it only ever receives `hex`.
struct SavedColor: Codable, Identifiable, Hashable {
    let hex: String

    var id: String { hex }

    init(hex: String) {
        self.hex = hex.normalizedHexColor ?? hex
    }
}
