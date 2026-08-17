import SwiftUI

struct MediaSearchView: View {
    @State private var viewModel: MediaListViewModel

    private let term: String

    init(term: String, service: any MediaService, toastStore: ToastStore) {
        self.term = term
        self._viewModel = State(
            initialValue: MediaListViewModel(source: .search(term: term), service: service, toastStore: toastStore)
        )
    }

    var body: some View {
        MediaList(
            viewModel: viewModel,
            emptyTitle: "Nothing found",
            emptyMessage: "No movies or series match \"\(term)\"."
        )
        .navigationTitle(term)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color("BackgroundPrimary").ignoresSafeArea())
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
    }
}

#Preview {
    NavigationStack {
        MediaSearchView(
            term: "Breaking",
            service: MockMediaService(operationDelay: .milliseconds(300)),
            toastStore: ToastStore()
        )
    }
}
