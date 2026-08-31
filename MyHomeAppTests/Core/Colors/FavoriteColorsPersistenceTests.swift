import Foundation
import Testing
@testable import MyHomeApp

struct FavoriteColorsPersistenceTests {
    private let defaults: UserDefaults
    private let persistence: UserDefaultsFavoriteColorsPersistence

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "com.myhome.tests.\(UUID().uuidString)"))
        persistence = UserDefaultsFavoriteColorsPersistence(key: "test.favoriteColors", defaults: defaults)
    }

    @Test
    func loadReturnsNothingWhenNoneWereSaved() throws {
        #expect(try persistence.load().isEmpty)
    }

    @Test
    func saveThenLoadRoundTripsTheColours() throws {
        let colors = [FavoriteColor(hex: "#FF7A45"), FavoriteColor(hex: "#4ADE80")]

        try persistence.save(colors)

        #expect(try persistence.load() == colors)
    }

    @Test
    func saveOverwritesThePreviousList() throws {
        try persistence.save([FavoriteColor(hex: "#FF7A45")])

        try persistence.save([])

        #expect(try persistence.load().isEmpty)
    }
}
