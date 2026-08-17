import Foundation
@testable import MyHomeApp

final class StubMediaService: MediaService, @unchecked Sendable {
    var healthy = true
    var libraryResult: Result<Page<MediaItem>, Error> = .success(.fixture(items: []))
    var searchResult: Result<Page<MediaItem>, Error> = .success(.fixture(items: []))
    var detailsResult: Result<MediaDetails, Error> = .success(.fixture())
    var downloadError: Error?
    var removeError: Error?

    private(set) var healthCalls: [Server] = []
    private(set) var libraryCalls: [(kind: MediaKindFilter, page: Int)] = []
    private(set) var searchCalls: [(term: String, kind: MediaKindFilter, page: Int)] = []
    private(set) var detailsCalls: [String] = []
    private(set) var downloadCalls: [String] = []
    private(set) var removeCalls: [String] = []

    func isHealthy(server: Server) async -> Bool {
        healthCalls.append(server)
        return healthy
    }

    func search(term: String, kind: MediaKindFilter, page: Int) async throws -> Page<MediaItem> {
        searchCalls.append((term, kind, page))
        return try searchResult.get()
    }

    func fetchLibrary(kind: MediaKindFilter, page: Int) async throws -> Page<MediaItem> {
        libraryCalls.append((kind, page))
        return try libraryResult.get()
    }

    func fetchDetails(mediaExternalId: String) async throws -> MediaDetails {
        detailsCalls.append(mediaExternalId)
        return try detailsResult.get()
    }

    func download(mediaExternalId: String) async throws {
        downloadCalls.append(mediaExternalId)
        if let downloadError { throw downloadError }
    }

    func remove(mediaExternalId: String) async throws {
        removeCalls.append(mediaExternalId)
        if let removeError { throw removeError }
    }
}
