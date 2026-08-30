/// Naming rules and display wording for a scenario's `group`.
///
/// The hub owns the vocabulary — a group is created implicitly by the first scenario that names it —
/// so `Scenario.group` stays a plain optional string. `nil` means the scenario has no group at all;
/// there is no "none" group on the hub.
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

    /// English letters, digits and underscores only, and never digits alone — the hub's rule.
    static func isValid(_ name: String) -> Bool {
        guard ScenarioLimits.groupNameLength.contains(name.count) else { return false }
        guard name.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }) else { return false }
        return !name.allSatisfy(\.isNumber)
    }
}
