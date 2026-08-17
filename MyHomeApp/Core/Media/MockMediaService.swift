import Foundation

struct MockMediaService: MediaService {
    static let allMedia: [MediaItem] = [
        MediaItem(
            externalId: "tt0111161",
            title: "The Shawshank Redemption",
            kind: .movie,
            year: 1994,
            posterUrl: nil,
            overview: "Two imprisoned men bond over a number of years, finding solace and eventual redemption."
        ),
        MediaItem(
            externalId: "tt0903747",
            title: "Breaking Bad",
            kind: .series,
            year: 2008,
            posterUrl: nil,
            overview: "A chemistry teacher turned methamphetamine producer partners with a former student."
        ),
        MediaItem(
            externalId: "tt1375666",
            title: "Inception",
            kind: .movie,
            year: 2010,
            posterUrl: nil,
            overview: "A thief who steals corporate secrets through dream-sharing technology."
        ),
        MediaItem(
            externalId: "tt0944947",
            title: "Game of Thrones",
            kind: .series,
            year: 2011,
            posterUrl: nil,
            overview: "Nine noble families fight for control over the lands of Westeros."
        )
    ]

    private let operationDelay: Duration

    init(operationDelay: Duration = .seconds(1)) {
        self.operationDelay = operationDelay
    }

    func isHealthy(server: Server) async -> Bool {
        try? await Task.sleep(for: operationDelay)
        return server.baseURL != nil
    }

    func search(term: String, kind: MediaKindFilter, page: Int) async throws -> Page<MediaItem> {
        try await Task.sleep(for: operationDelay)
        let matches = Self.allMedia
            .filter { $0.title.localizedCaseInsensitiveContains(term) }
            .filter { matches(kind, $0) }
        return Self.page(matches, page: page)
    }

    func fetchLibrary(kind: MediaKindFilter, page: Int) async throws -> Page<MediaItem> {
        try await Task.sleep(for: operationDelay)
        return Self.page(Self.allMedia.filter { matches(kind, $0) }, page: page)
    }

    func fetchDetails(mediaExternalId: String) async throws -> MediaDetails {
        try await Task.sleep(for: operationDelay)
        guard let item = Self.allMedia.first(where: { $0.externalId == mediaExternalId }) else {
            throw HubAPIError.notFound
        }
        return MediaDetails(
            externalId: item.externalId,
            title: item.title,
            kind: item.kind,
            year: item.year,
            posterUrl: item.posterUrl,
            overview: item.overview,
            genres: ["Drama", "Thriller"],
            rating: 8.7,
            runtimeMinutes: 142,
            inLibrary: item.kind == .movie
        )
    }

    func download(mediaExternalId _: String) async throws {
        try await Task.sleep(for: operationDelay)
    }

    func remove(mediaExternalId _: String) async throws {
        try await Task.sleep(for: operationDelay)
    }

    private func matches(_ filter: MediaKindFilter, _ item: MediaItem) -> Bool {
        switch filter {
        case .all: return true
        case .specific(let kind): return item.kind == kind
        }
    }

    private static func page(_ items: [MediaItem], page: Int) -> Page<MediaItem> {
        Page(items: items, page: page, pageSize: items.count, totalPages: 1, totalItems: items.count)
    }
}
