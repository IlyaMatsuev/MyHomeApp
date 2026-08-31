import Foundation
import Testing
@testable import MyHomeApp

struct SavedColorsPersistenceTests {
    private let defaults: UserDefaults
    private let persistence: UserDefaultsSavedColorsPersistence

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "com.myhome.tests.\(UUID().uuidString)"))
        persistence = UserDefaultsSavedColorsPersistence(key: "test.savedColors", defaults: defaults)
    }

    @Test
    func loadReturnsNothingWhenNoneWereSaved() throws {
        #expect(try persistence.load().isEmpty)
    }

    @Test
    func saveThenLoadRoundTripsTheColours() throws {
        let colors = [SavedColor(hex: "#FF7A45"), SavedColor(hex: "#4ADE80")]

        try persistence.save(colors)

        #expect(try persistence.load() == colors)
    }

    @Test
    func saveOverwritesThePreviousList() throws {
        try persistence.save([SavedColor(hex: "#FF7A45")])

        try persistence.save([])

        #expect(try persistence.load().isEmpty)
    }
}
