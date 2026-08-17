import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct HubMediaServiceTests {
    private let client: StubMyHomeAPIClient
    private let mediaServer = Server(.http, "media.home:8080", label: "Media Manager")

    private var service: HubMediaService {
        makeService(server: mediaServer)
    }

    init() {
        client = StubMyHomeAPIClient()
    }

    private func makeService(server: Server?) -> HubMediaService {
        HubMediaService(client: client) { server }
    }

    // MARK: - isHealthy()

    @Test
    func isHealthyCallsHealthOnTheGivenServer() async throws {
        let healthy = await service.isHealthy(server: mediaServer)

        let request = try #require(client.sentRequests.first)
        let target = try #require(client.sentTargets.first)
        #expect(healthy)
        #expect(request.path == "/health")
        #expect(request.method == .get)
        #expect(target == mediaServer)
    }

    @Test
    func isHealthyIsFalseWhenTheRequestFails() async {
        client.response = .error(HubAPIError.transport)

        let healthy = await service.isHealthy(server: mediaServer)

        #expect(healthy == false)
    }

    // MARK: - fetchLibrary()

    @Test
    func fetchLibrarySendsPagingAndTypeQuery() async throws {
        let expected = Page.fixture(items: [MediaItem.fixture()])
        client.response = .data(try JSONEncoder().encode(expected))

        let page = try await service.fetchLibrary(kind: .specific(.series), page: 3)

        let request = try #require(client.sentRequests.first)
        let target = try #require(client.sentTargets.first)
        #expect(request.path == "/media/library")
        #expect(request.query["page"] == "3")
        #expect(request.query["pageSize"] == "20")
        #expect(request.query["type"] == "series")
        #expect(request.protected)
        #expect(target == mediaServer)
        #expect(page.items == expected.items)
    }

    @Test
    func fetchLibraryOmitsTheTypeQueryForTheAllFilter() async throws {
        client.response = .data(try JSONEncoder().encode(Page.fixture(items: [MediaItem]())))

        _ = try await service.fetchLibrary(kind: .all, page: 1)

        let request = try #require(client.sentRequests.first)
        #expect(request.query["type"] == nil)
        #expect(request.query["page"] == "1")
    }

    // MARK: - search()

    @Test
    func searchSendsTheTermAlongWithPaging() async throws {
        client.response = .data(try JSONEncoder().encode(Page.fixture(items: [MediaItem.fixture()])))

        _ = try await service.search(term: "matrix", kind: .specific(.movie), page: 2)

        let request = try #require(client.sentRequests.first)
        #expect(request.path == "/media/search")
        #expect(request.query["term"] == "matrix")
        #expect(request.query["type"] == "movie")
        #expect(request.query["page"] == "2")
    }

    // MARK: - fetchDetails()

    @Test
    func fetchDetailsRequestsTheLibraryEntry() async throws {
        let expected = MediaDetails.fixture(externalId: "tt42", inLibrary: true)
        client.response = .data(try JSONEncoder().encode(expected))

        let details = try await service.fetchDetails(mediaExternalId: "tt42")

        let request = try #require(client.sentRequests.first)
        #expect(request.path == "/media/library/tt42")
        #expect(details == expected)
    }

    // MARK: - download() / remove()

    @Test
    func downloadPostsToTheLibraryEntry() async throws {
        try await service.download(mediaExternalId: "tt42")

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .post)
        #expect(request.path == "/media/library/tt42")
        #expect(request.protected)
    }

    @Test
    func removeDeletesTheLibraryEntry() async throws {
        try await service.remove(mediaExternalId: "tt42")

        let request = try #require(client.sentRequests.first)
        #expect(request.method == .delete)
        #expect(request.path == "/media/library/tt42")
    }

    // MARK: - unconfigured Media Manager

    @Test
    func requestsFailWhenNoAddressIsConfigured() async {
        let service = makeService(server: nil)

        await #expect(throws: MediaError.notConfigured) {
            _ = try await service.fetchLibrary(kind: .all, page: 1)
        }
        #expect(client.sentRequests.isEmpty)
    }

    @Test
    func requestsFailWhenTheConfiguredAddressIsUnusable() async {
        let service = makeService(server: Server(.http, ""))

        await #expect(throws: MediaError.notConfigured) {
            try await service.download(mediaExternalId: "tt42")
        }
        #expect(client.sentRequests.isEmpty)
    }
}
