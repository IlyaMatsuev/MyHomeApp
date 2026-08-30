/// Naming rules and display wording for a scenario's `group`.
enum ScenarioGroupName {
    static let ungroupedLabel = "Ungrouped"

    /// `living_room` -> `Living Room`, `nil` -> `Ungrouped`.
    static func label(for group: String?) -> String {
        guard let group, !group.isBlank else { return ungroupedLabel }
        return group
            .split(whereSeparator: { $0 == "_" || $0 == "-" || $0 == " " })
            .map(\.capitalized)
            .joined(separator: " ")
    }

    /// `Living Room` -> `living_room`, the name the hub stores.
    static func apiName(for label: String) -> String {
        label
            .split(whereSeparator: { $0 == "_" || $0 == "-" || $0.isWhitespace })
            .joined(separator: "_")
            .lowercased()
    }

    /// English letters, digits and underscores only, and never digits alone
    static func isValid(_ name: String) -> Bool {
        guard ScenarioLimits.groupNameLength.contains(name.count) else { return false }
        guard name.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }) else { return false }
        return !name.allSatisfy(\.isNumber)
    }
}
