import Foundation

extension String {
    /// Matches the hub's `@IsIP(4)` check on a device's `ip` field.
    var isIPv4Address: Bool {
        let parts = split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            part.count <= 3 && !part.isEmpty && part.allSatisfy(\.isNumber) && (Int(part) ?? 256) <= 255
        }
    }
}
