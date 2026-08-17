enum MediaKind: String, Codable, Hashable, CaseIterable, Identifiable, Sendable {
    case movie
    case series

    var id: String { rawValue }

    var label: String {
        switch self {
        case .movie: return "Movie"
        case .series: return "Series"
        }
    }

    var pluralLabel: String {
        switch self {
        case .movie: return "Movies"
        case .series: return "Series"
        }
    }

    var icon: String {
        switch self {
        case .movie: return "film"
        case .series: return "tv"
        }
    }
}
