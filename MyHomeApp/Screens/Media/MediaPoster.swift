import SwiftUI

struct MediaPoster: View {
    let url: URL?
    let kind: MediaKind
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            placeholder
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var placeholder: some View {
        Image(systemName: kind.icon)
            .font(.title3)
            .foregroundStyle(Color("AccentPrimary"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("BackgroundTertiary"))
    }
}
