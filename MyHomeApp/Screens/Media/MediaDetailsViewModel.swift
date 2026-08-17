import Foundation
import Observation
import os

@Observable
@MainActor
final class MediaDetailsViewModel {
    private static let logger = Logger(subsystem: "MyHomeApp", category: "MediaDetailsViewModel")

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    let item: MediaItem

    private(set) var state: LoadState = .idle
    private(set) var details: MediaDetails?
    private(set) var updating = false

    private let service: any MediaService
    private let toastStore: ToastStore

    var inLibrary: Bool {
        details?.inLibrary ?? false
    }

    init(item: MediaItem, service: any MediaService, toastStore: ToastStore) {
        self.item = item
        self.service = service
        self.toastStore = toastStore
    }

    func load() async {
        state = .loading
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    /// Downloads the title when it is not in the library yet, removes it otherwise.
    func toggleLibrary() async {
        guard !updating else { return }

        updating = true
        defer { updating = false }

        do {
            if inLibrary {
                try await service.remove(mediaExternalId: item.externalId)
            } else {
                try await service.download(mediaExternalId: item.externalId)
            }
            await fetch()
        } catch {
            Self.logger.error("Failed to update the library for \"\(item.externalId)\": \(error.localizedDescription)")
            toastStore.error(MediaErrorMessage.text(for: error))
        }
    }

    private func fetch() async {
        do {
            details = try await service.fetchDetails(mediaExternalId: item.externalId)
            state = .loaded
        } catch HubAPIError.notFound {
            // Search results are not in the library yet, so the Media Manager has nothing stored for them.
            details = MediaDetails(item: item, inLibrary: false)
            state = .loaded
        } catch {
            Self.logger.error("Failed to load details for \"\(item.externalId)\": \(error.localizedDescription)")
            state = .failed(MediaErrorMessage.text(for: error))
        }
    }
}
