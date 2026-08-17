import Foundation

struct MediaItem: Codable, Identifiable, Hashable, Sendable {
    let externalId: String
    let title: String
    let kind: MediaKind
    let year: Int?
    let posterUrl: String?
    let overview: String?

    var id: String { externalId }

    var posterURL: URL? {
        guard let posterUrl else { return nil }
        return URL(string: posterUrl)
    }

    var subtitle: String {
        guard let year else { return kind.label }
        return "\(kind.label) · \(year)"
    }
}
