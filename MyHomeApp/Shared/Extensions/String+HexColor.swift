import Foundation

extension String {
    private static let hexColorRegex = /^#?(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/

    /// Matches the hub's `hex-color` config format, which accepts 3, 4, 6 and 8 digit values.
    var isHexColor: Bool {
        (try? Self.hexColorRegex.wholeMatch(in: self)) != nil
    }

    /// The same colour written as `#RRGGBB…` in upper case, or `nil` when this isn't a hex colour.
    ///
    /// Saved colors go through this so two spellings of one colour can't both be stored.
    var normalizedHexColor: String? {
        let trimmed = trimmed
        guard trimmed.isHexColor else { return nil }
        return "#" + trimmed.drop { $0 == "#" }.uppercased()
    }
}
