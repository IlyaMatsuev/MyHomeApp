import SwiftUI

/// Paginated, refreshable list of media entries shared by the library and the search results.
struct MediaList: View {
    @Bindable var viewModel: MediaListViewModel

    let emptyTitle: String
    let emptyMessage: String

    var body: some View {
        VStack(spacing: 0) {
            MediaKindFilterList(selection: $viewModel.selectedKind)
            list
        }
    }

    private var list: some View {
        List {
            content
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            placeholderRow {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            }

        case .failed(let message):
            placeholderRow {
                ContentUnavailableView(
                    "Couldn't load media",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }

        case .loaded:
            if viewModel.items.isEmpty {
                placeholderRow {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: "film.stack",
                        description: Text(emptyMessage)
                    )
                }
            } else {
                itemRows
            }
        }
    }

    @ViewBuilder
    private var itemRows: some View {
        ForEach(viewModel.items) { item in
            NavigationLink(value: MediaRoute.details(item)) {
                MediaListRow(item: item)
            }
            .onAppear { viewModel.loadNextPageIfNeeded(after: item) }
        }

        if viewModel.loadingMore {
            placeholderRow {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }

    /// Keeps non-item states inside the list so pull-to-refresh stays available.
    private func placeholderRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
