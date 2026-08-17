import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct MediaListViewModelTests {
    /// Gives the `Task` spawned by a filter change or by pagination time to finish.
    private static let backgroundWork = Duration.milliseconds(50)

    private let service: StubMediaService
    private let toastStore: ToastStore
    private let viewModel: MediaListViewModel

    init() {
        service = StubMediaService()
        toastStore = ToastStore()
        viewModel = MediaListViewModel(source: .library, service: service, toastStore: toastStore)
    }

    // MARK: - init

    @Test
    func startsIdleWithTheAllFilter() {
        #expect(viewModel.state == .idle)
        #expect(viewModel.selectedKind == .all)
        #expect(viewModel.items.isEmpty)
    }

    // MARK: - load()

    @Test
    func loadFetchesTheFirstLibraryPage() async throws {
        let items = [MediaItem.fixture(externalId: "a"), MediaItem.fixture(externalId: "b")]
        service.libraryResult = .success(.fixture(items: items))

        await viewModel.load()

        let call = try #require(service.libraryCalls.first)
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items == items)
        #expect(service.libraryCalls.count == 1)
        #expect(call.page == 1)
        #expect(call.kind == .all)
    }

    @Test
    func loadForASearchSourcePassesTheTerm() async throws {
        let viewModel = MediaListViewModel(
            source: .search(term: "matrix"),
            service: service,
            toastStore: toastStore
        )
        service.searchResult = .success(.fixture(items: [MediaItem.fixture()]))

        await viewModel.load()

        let call = try #require(service.searchCalls.first)
        #expect(call.term == "matrix")
        #expect(call.page == 1)
        #expect(service.libraryCalls.isEmpty)
    }

    @Test
    func loadWhenServiceFailsSetsFailedStateWithAFriendlyMessage() async {
        service.libraryResult = .failure(HubAPIError.transport)

        await viewModel.load()

        #expect(viewModel.state == .failed("Couldn't reach the Media Manager. Are you connected to the same network?"))
        #expect(viewModel.items.isEmpty)
    }

    @Test
    func loadWhenTheMediaManagerIsNotConfiguredExplainsWhy() async {
        service.libraryResult = .failure(MediaError.notConfigured)

        await viewModel.load()

        #expect(viewModel.state == .failed("The Media Manager is not configured. Add its address in Settings."))
    }

    // MARK: - pagination

    @Test
    func loadNextPageAppendsTheFollowingPage() async throws {
        let first = MediaItem.fixture(externalId: "a")
        let second = MediaItem.fixture(externalId: "b")
        service.libraryResult = .success(.fixture(items: [first], page: 1, totalPages: 2))
        await viewModel.load()
        service.libraryResult = .success(.fixture(items: [second], page: 2, totalPages: 2))

        viewModel.loadNextPageIfNeeded(after: first)
        try await Task.sleep(for: Self.backgroundWork)

        let call = try #require(service.libraryCalls.last)
        #expect(viewModel.items == [first, second])
        #expect(call.page == 2)
        #expect(viewModel.hasMorePages == false)
    }

    @Test
    func loadNextPageIsIgnoredOnTheLastPage() async throws {
        let item = MediaItem.fixture(externalId: "a")
        service.libraryResult = .success(.fixture(items: [item], page: 1, totalPages: 1))
        await viewModel.load()

        viewModel.loadNextPageIfNeeded(after: item)
        try await Task.sleep(for: Self.backgroundWork)

        #expect(service.libraryCalls.count == 1)
    }

    @Test
    func loadNextPageIsIgnoredForRowsAboveTheLastOne() async throws {
        let first = MediaItem.fixture(externalId: "a")
        let last = MediaItem.fixture(externalId: "b")
        service.libraryResult = .success(.fixture(items: [first, last], page: 1, totalPages: 3))
        await viewModel.load()

        viewModel.loadNextPageIfNeeded(after: first)
        try await Task.sleep(for: Self.backgroundWork)

        #expect(service.libraryCalls.count == 1)
    }

    @Test
    func failingNextPageKeepsTheItemsAndSurfacesAToast() async throws {
        let item = MediaItem.fixture(externalId: "a")
        service.libraryResult = .success(.fixture(items: [item], page: 1, totalPages: 2))
        await viewModel.load()
        service.libraryResult = .failure(HubAPIError.transport)

        viewModel.loadNextPageIfNeeded(after: item)
        try await Task.sleep(for: Self.backgroundWork)

        let toast = try #require(toastStore.current)
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items == [item])
        #expect(toast.kind == .error)
    }

    // MARK: - refresh()

    @Test
    func refreshReplacesTheItemsWithTheFirstPage() async throws {
        service.libraryResult = .success(.fixture(items: [MediaItem.fixture(externalId: "a")]))
        await viewModel.load()
        let refreshed = [MediaItem.fixture(externalId: "c")]
        service.libraryResult = .success(.fixture(items: refreshed))

        await viewModel.refresh()

        let call = try #require(service.libraryCalls.last)
        #expect(viewModel.items == refreshed)
        #expect(call.page == 1)
    }

    // MARK: - selectedKind

    @Test
    func changingTheFilterReloadsWithTheNewKind() async throws {
        service.libraryResult = .success(.fixture(items: [MediaItem.fixture()]))
        await viewModel.load()

        viewModel.selectedKind = .specific(.series)
        try await Task.sleep(for: Self.backgroundWork)

        let call = try #require(service.libraryCalls.last)
        #expect(service.libraryCalls.count == 2)
        #expect(call.kind == .specific(.series))
        #expect(call.page == 1)
    }

    @Test
    func settingTheSameFilterDoesNotReload() async throws {
        service.libraryResult = .success(.fixture(items: [MediaItem.fixture()]))
        await viewModel.load()

        viewModel.selectedKind = .all
        try await Task.sleep(for: Self.backgroundWork)

        #expect(service.libraryCalls.count == 1)
    }
}
