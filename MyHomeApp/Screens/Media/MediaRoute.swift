enum MediaRoute: Hashable {
    case search(term: String)
    case details(MediaItem)
}
