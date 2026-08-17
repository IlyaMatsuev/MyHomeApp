import Foundation

/// A scenario's group as it comes from the hub.
///
/// Unlike `DeviceRoom` this is deliberately **not** a closed enum: the hub owns the vocabulary
/// (`living_room`, `none`, …) and may extend it at any time. Keeping it a transparent string
/// wrapper means a new group can never fail decoding of a whole scenarios page.
struct ScenarioGroup: Codable, Hashable, Identifiable {
    static let general = ScenarioGroup("none")

    let rawValue: String

    var id: String { rawValue }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ScenarioGroup {
    var isGeneral: Bool {
        rawValue.isEmpty || rawValue == Self.general.rawValue
    }

    /// `living_room` -> `Living Room`, `none` -> `General`.
    var label: String {
        guard !isGeneral else { return "General" }
        return rawValue
            .split(whereSeparator: { $0 == "_" || $0 == "-" || $0 == " " })
            .map(\.capitalized)
            .joined(separator: " ")
    }
}

extension ScenarioGroup: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        // "General" (no group) is at the top
        if lhs.isGeneral != rhs.isGeneral {
            return lhs.isGeneral
        }
        return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
    }
}
