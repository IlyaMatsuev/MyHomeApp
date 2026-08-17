import Foundation
@testable import MyHomeApp

extension MediaItem {
    static func fixture(
        externalId: String = "tt0000001",
        title: String = "Test Movie",
        kind: MediaKind = .movie,
        year: Int? = 2020,
        posterUrl: String? = nil,
        overview: String? = nil
    ) -> MediaItem {
        MediaItem(
            externalId: externalId,
            title: title,
            kind: kind,
            year: year,
            posterUrl: posterUrl,
            overview: overview
        )
    }
}

extension MediaDetails {
    static func fixture(
        externalId: String = "tt0000001",
        title: String = "Test Movie",
        kind: MediaKind = .movie,
        inLibrary: Bool = false
    ) -> MediaDetails {
        MediaDetails(externalId: externalId, title: title, kind: kind, inLibrary: inLibrary)
    }
}

extension Page {
    static func fixture(items: [Item], page: Int = 1, totalPages: Int = 1) -> Page<Item> {
        Page(
            items: items,
            page: page,
            pageSize: items.count,
            totalPages: totalPages,
            totalItems: items.count
        )
    }
}
