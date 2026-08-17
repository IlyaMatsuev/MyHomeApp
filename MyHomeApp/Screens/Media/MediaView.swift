import SwiftUI

struct MediaView: View {
    @State private var viewModel: MediaListViewModel
    @State private var path: [MediaRoute] = []
    @State private var searchTerm = ""

    private let service: any MediaService
    private let toastStore: ToastStore

    init(service: any MediaService, toastStore: ToastStore) {
        self.service = service
        self.toastStore = toastStore
        self._viewModel = State(
            initialValue: MediaListViewModel(source: .library, service: service, toastStore: toastStore)
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            MediaList(
                viewModel: viewModel,
                emptyTitle: "Your library is empty",
                emptyMessage: "Movies and series you download will show up here."
            )
            .navigationTitle("Media")
            .background(Color("BackgroundPrimary").ignoresSafeArea())
            .searchable(
                text: $searchTerm,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search movies and series"
            )
            .onSubmit(of: .search) { submitSearch() }
            .navigationDestination(for: MediaRoute.self) { route in
                destination(for: route)
            }
            .task {
                if viewModel.state == .idle {
                    await viewModel.load()
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: MediaRoute) -> some View {
        switch route {
        case .search(let term):
            MediaSearchView(term: term, service: service, toastStore: toastStore)

        case .details(let item):
            MediaDetailsView(item: item, service: service, toastStore: toastStore)
        }
    }

    private func submitSearch() {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        path.append(.search(term: term))
    }
}

#Preview {
    MediaView(service: MockMediaService(operationDelay: .milliseconds(300)), toastStore: ToastStore())
}
