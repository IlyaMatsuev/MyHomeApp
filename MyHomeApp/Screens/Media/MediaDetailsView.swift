import SwiftUI

struct MediaDetailsView: View {
    @State private var viewModel: MediaDetailsViewModel

    init(item: MediaItem, service: any MediaService, toastStore: ToastStore) {
        self._viewModel = State(
            initialValue: MediaDetailsViewModel(item: item, service: service, toastStore: toastStore)
        )
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity)
                .padding(24)
        }
        .refreshable { await viewModel.refresh() }
        .background(Color("BackgroundPrimary").ignoresSafeArea())
        .navigationTitle(viewModel.item.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .padding(.top, 64)

        case .failed(let message):
            ContentUnavailableView(
                "Couldn't load this title",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .padding(.top, 32)

        case .loaded:
            if let details = viewModel.details {
                loaded(details)
            }
        }
    }

    private func loaded(_ details: MediaDetails) -> some View {
        VStack(spacing: 20) {
            MediaPoster(url: details.posterURL, kind: details.kind, width: 160, height: 230)

            VStack(spacing: 6) {
                Text(details.title)
                    .font(.title2.bold())
                    .foregroundStyle(Color("TextPrimary"))
                    .multilineTextAlignment(.center)

                Text(details.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color("TextSecondary"))

                if let rating = details.rating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color("AccentSecondary"))
                }
            }

            if !details.genres.isEmpty {
                Text(details.genres.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }

            if let overview = details.overview, !overview.isEmpty {
                Text(overview)
                    .font(.body)
                    .foregroundStyle(Color("TextPrimary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            libraryButton(details)
        }
    }

    private func libraryButton(_ details: MediaDetails) -> some View {
        Button {
            Task { await viewModel.toggleLibrary() }
        } label: {
            ZStack {
                Label(
                    details.inLibrary ? "Remove" : "Download",
                    systemImage: details.inLibrary ? "trash" : "arrow.down.circle"
                )
                .opacity(viewModel.updating ? 0 : 1)

                if viewModel.updating {
                    ProgressView().tint(.white)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(details.inLibrary ? Color("Danger") : Color("AccentPrimary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.updating)
    }
}

#Preview {
    NavigationStack {
        MediaDetailsView(
            item: MockMediaService.allMedia[0],
            service: MockMediaService(operationDelay: .milliseconds(300)),
            toastStore: ToastStore()
        )
    }
}
