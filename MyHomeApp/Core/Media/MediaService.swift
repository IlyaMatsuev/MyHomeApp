protocol MediaService: Sendable {
    /// Validates an address by calling `GET /health` on it.
    func isHealthy(server: Server) async -> Bool

    func search(term: String, kind: MediaKindFilter, page: Int) async throws -> Page<MediaItem>
    func fetchLibrary(kind: MediaKindFilter, page: Int) async throws -> Page<MediaItem>
    func fetchDetails(mediaExternalId: String) async throws -> MediaDetails

    func download(mediaExternalId: String) async throws
    func remove(mediaExternalId: String) async throws
}
