import Foundation

extension String {
    /// Turns a wire field name into something readable: `speedPercentage` → `Speed percentage`.
    ///
    /// Only used as a fallback label for a device the hub ships no config for — a config always
    /// carries a proper `label`.
    var humanized: String {
        let spaced = replacingOccurrences(
            of: "([a-z0-9])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        .replacingOccurrences(of: "[_-]+", with: " ", options: .regularExpression)
        .trimmed

        guard let first = spaced.first else { return spaced }
        return first.uppercased() + spaced.dropFirst().lowercased()
    }
}
