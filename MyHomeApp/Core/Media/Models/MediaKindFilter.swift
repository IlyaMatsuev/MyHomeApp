enum MediaKindFilter: Hashable, Sendable {
    case all
    case specific(MediaKind)
}

extension MediaKindFilter {
    static var allFilters: [MediaKindFilter] {
        [.all] + MediaKind.allCases.map(Self.specific)
    }

    var label: String {
        switch self {
        case .all: return "All"
        case .specific(let kind): return kind.pluralLabel
        }
    }

    /// Value sent to the Media Manager as the `type` query parameter. `nil` means "no filtering".
    var queryValue: String? {
        switch self {
        case .all: return nil
        case .specific(let kind): return kind.rawValue
        }
    }
}
