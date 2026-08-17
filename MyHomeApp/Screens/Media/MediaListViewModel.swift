import Foundation
import Observation
import os

/// Backs both paginated media lists: the library on the Media tab and the search results screen.
@Observable
@MainActor
final class MediaListViewModel {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "MediaListViewModel")

    enum Source: Hashable {
        case library
        case search(term: String)
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var selectedKind: MediaKindFilter {
        didSet {
            guard oldValue != selectedKind else { return }
            Task { await load() }
        }
    }

    private(set) var state: LoadState = .idle
    private(set) var items: [MediaItem] = []
    private(set) var loadingMore = false

    private let source: Source
    private let service: any MediaService
    private let toastStore: ToastStore

    private var currentPage = 0
    private var totalPages = 1
    private var loadingFirstPage = false
    /// Identifies the latest started request so responses of superseded ones can be dropped.
    private var requestId = 0

    var hasMorePages: Bool {
        currentPage < totalPages
    }

    init(
        source: Source,
        service: any MediaService,
        toastStore: ToastStore,
        selectedKind: MediaKindFilter = .all
    ) {
        self.source = source
        self.service = service
        self.toastStore = toastStore
        self.selectedKind = selectedKind
    }

    func load() async {
        state = .loading
        await fetch(page: 1, replacing: true)
    }

    /// Pull-to-refresh: reloads the first page while the current items stay on screen.
    func refresh() async {
        await fetch(page: 1, replacing: true)
    }

    func loadNextPageIfNeeded(after item: MediaItem) {
        guard state == .loaded, hasMorePages, !loadingMore, !loadingFirstPage, items.last?.id == item.id else {
            return
        }
        Task { await loadNextPage() }
    }

    private func loadNextPage() async {
        loadingMore = true
        defer { loadingMore = false }
        await fetch(page: currentPage + 1, replacing: false)
    }

    private func fetch(page: Int, replacing: Bool) async {
        requestId += 1
        let startedRequestId = requestId

        if replacing {
            loadingFirstPage = true
        }
        defer {
            if replacing {
                loadingFirstPage = false
            }
        }

        do {
            let result = try await fetchPage(page)
            guard startedRequestId == requestId else { return }

            items = replacing ? result.items : items + result.items
            currentPage = result.page
            totalPages = max(result.totalPages, 1)
            state = .loaded
        } catch {
            guard startedRequestId == requestId else { return }

            Self.logger.error("Failed to load media page \(page): \(error.localizedDescription)")
            if replacing {
                items = []
                state = .failed(MediaErrorMessage.text(for: error))
            } else {
                toastStore.error(MediaErrorMessage.text(for: error))
            }
        }
    }

    private func fetchPage(_ page: Int) async throws -> Page<MediaItem> {
        switch source {
        case .library:
            return try await service.fetchLibrary(kind: selectedKind, page: page)

        case .search(let term):
            return try await service.search(term: term, kind: selectedKind, page: page)
        }
    }
}
