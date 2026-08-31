import SwiftUI

extension Color {
    /// Builds a colour from a `#RGB` / `#RGBA` / `#RRGGBB` / `#RRGGBBAA` string — the shapes the
    /// hub's `hex-color` format accepts — or `nil` when the text isn't a hex colour.
    ///
    /// Used to preview a device's colour control next to its text field.
    init?(hex: String) {
        var digits = hex.trimmed
        if digits.hasPrefix("#") {
            digits.removeFirst()
        }
        if digits.count == 3 || digits.count == 4 {
            digits = digits.map { "\($0)\($0)" }.joined()
        }
        guard digits.count == 6 || digits.count == 8, let value = UInt32(digits, radix: 16) else { return nil }

        let rgb = digits.count == 8 ? value >> 8 : value
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: digits.count == 8 ? Double(value & 0xFF) / 255 : 1
        )
    }

    /// The colour written back as `#RRGGBB`, or `nil` when it can't be resolved into components.
    ///
    /// The system colour picker hands back a `Color`, but the hub only stores hex strings. Wide-gamut
    /// picks are clamped into sRGB, since that is all the devices understand.
    var hexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }

        return String(format: "#%02X%02X%02X", channel(red), channel(green), channel(blue))
    }

    private func channel(_ value: CGFloat) -> Int {
        Int((min(max(value, 0), 1) * 255).rounded())
    }
}
