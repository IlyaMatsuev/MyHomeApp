import Foundation

struct MediaDetails: Codable, Identifiable, Hashable, Sendable {
    let externalId: String
    let title: String
    let kind: MediaKind
    let year: Int?
    let posterUrl: String?
    let overview: String?
    let genres: [String]
    let rating: Double?
    let runtimeMinutes: Int?
    let inLibrary: Bool

    var id: String { externalId }

    var posterURL: URL? {
        guard let posterUrl else { return nil }
        return URL(string: posterUrl)
    }

    var subtitle: String {
        var parts = [kind.label]
        if let year {
            parts.append(String(year))
        }
        if let runtimeMinutes {
            parts.append("\(runtimeMinutes) min")
        }
        return parts.joined(separator: " · ")
    }

    init(
        externalId: String,
        title: String,
        kind: MediaKind,
        year: Int? = nil,
        posterUrl: String? = nil,
        overview: String? = nil,
        genres: [String] = [],
        rating: Double? = nil,
        runtimeMinutes: Int? = nil,
        inLibrary: Bool = false
    ) {
        self.externalId = externalId
        self.title = title
        self.kind = kind
        self.year = year
        self.posterUrl = posterUrl
        self.overview = overview
        self.genres = genres
        self.rating = rating
        self.runtimeMinutes = runtimeMinutes
        self.inLibrary = inLibrary
    }

    /// Fallback used when the Media Manager has no entry for a search result yet.
    init(item: MediaItem, inLibrary: Bool) {
        self.init(
            externalId: item.externalId,
            title: item.title,
            kind: item.kind,
            year: item.year,
            posterUrl: item.posterUrl,
            overview: item.overview,
            inLibrary: inLibrary
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            externalId: try container.decode(String.self, forKey: .externalId),
            title: try container.decode(String.self, forKey: .title),
            kind: try container.decode(MediaKind.self, forKey: .kind),
            year: try container.decodeIfPresent(Int.self, forKey: .year),
            posterUrl: try container.decodeIfPresent(String.self, forKey: .posterUrl),
            overview: try container.decodeIfPresent(String.self, forKey: .overview),
            genres: try container.decodeIfPresent([String].self, forKey: .genres) ?? [],
            rating: try container.decodeIfPresent(Double.self, forKey: .rating),
            runtimeMinutes: try container.decodeIfPresent(Int.self, forKey: .runtimeMinutes),
            inLibrary: try container.decodeIfPresent(Bool.self, forKey: .inLibrary) ?? false
        )
    }
}
