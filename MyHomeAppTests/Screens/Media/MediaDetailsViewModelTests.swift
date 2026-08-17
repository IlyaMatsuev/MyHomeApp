import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct MediaDetailsViewModelTests {
    private let service: StubMediaService
    private let toastStore: ToastStore
    private let item: MediaItem
    private let viewModel: MediaDetailsViewModel

    init() {
        let item = MediaItem.fixture(externalId: "tt42", title: "Test Movie", kind: .movie)
        let service = StubMediaService()
        let toastStore = ToastStore()

        self.item = item
        self.service = service
        self.toastStore = toastStore
        self.viewModel = MediaDetailsViewModel(item: item, service: service, toastStore: toastStore)
    }

    // MARK: - init

    @Test
    func startsIdle() {
        #expect(viewModel.state == .idle)
        #expect(viewModel.details == nil)
        #expect(viewModel.inLibrary == false)
    }

    // MARK: - load()

    @Test
    func loadFetchesTheDetailsOfTheItem() async {
        let details = MediaDetails.fixture(externalId: "tt42", inLibrary: true)
        service.detailsResult = .success(details)

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.details == details)
        #expect(viewModel.inLibrary)
        #expect(service.detailsCalls == ["tt42"])
    }

    @Test
    func loadFallsBackToTheListItemWhenTheEntryIsNotInTheLibrary() async throws {
        service.detailsResult = .failure(HubAPIError.notFound)

        await viewModel.load()

        let details = try #require(viewModel.details)
        #expect(viewModel.state == .loaded)
        #expect(details.title == item.title)
        #expect(details.externalId == item.externalId)
        #expect(details.inLibrary == false)
    }

    @Test
    func loadWhenServiceFailsSetsFailedState() async {
        service.detailsResult = .failure(HubAPIError.transport)

        await viewModel.load()

        #expect(viewModel.state == .failed("Couldn't reach the Media Manager. Are you connected to the same network?"))
        #expect(viewModel.details == nil)
    }

    // MARK: - toggleLibrary()

    @Test
    func toggleLibraryDownloadsWhenTheTitleIsNotInTheLibrary() async {
        service.detailsResult = .success(.fixture(externalId: "tt42", inLibrary: false))
        await viewModel.load()

        await viewModel.toggleLibrary()

        #expect(service.downloadCalls == ["tt42"])
        #expect(service.removeCalls.isEmpty)
    }

    @Test
    func toggleLibraryRemovesWhenTheTitleIsInTheLibrary() async {
        service.detailsResult = .success(.fixture(externalId: "tt42", inLibrary: true))
        await viewModel.load()

        await viewModel.toggleLibrary()

        #expect(service.removeCalls == ["tt42"])
        #expect(service.downloadCalls.isEmpty)
    }

    @Test
    func toggleLibraryReloadsTheDetailsAfterwards() async {
        service.detailsResult = .success(.fixture(externalId: "tt42", inLibrary: false))
        await viewModel.load()
        service.detailsResult = .success(.fixture(externalId: "tt42", inLibrary: true))

        await viewModel.toggleLibrary()

        #expect(service.detailsCalls.count == 2)
        #expect(viewModel.inLibrary)
    }

    @Test
    func toggleLibraryWhenTheRequestFailsSurfacesAToastAndKeepsTheState() async throws {
        service.detailsResult = .success(.fixture(externalId: "tt42", inLibrary: false))
        await viewModel.load()
        service.downloadError = HubAPIError.unexpected

        await viewModel.toggleLibrary()

        let toast = try #require(toastStore.current)
        #expect(toast.kind == .error)
        #expect(viewModel.inLibrary == false)
        #expect(viewModel.updating == false)
    }

    // MARK: - refresh()

    @Test
    func refreshFetchesTheDetailsAgain() async {
        service.detailsResult = .success(.fixture(externalId: "tt42"))
        await viewModel.load()

        await viewModel.refresh()

        #expect(service.detailsCalls.count == 2)
    }
}
