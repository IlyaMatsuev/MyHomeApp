protocol FavoriteColorsPersistence: Sendable {
    func load() throws -> [FavoriteColor]
    func save(_ colors: [FavoriteColor]) throws
}
