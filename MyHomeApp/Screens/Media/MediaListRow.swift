import SwiftUI

struct MediaListRow: View {
    let item: MediaItem

    var body: some View {
        HStack(spacing: 12) {
            MediaPoster(url: item.posterURL, kind: item.kind, width: 44, height: 62)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .foregroundStyle(Color("TextPrimary"))

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
    }
}
