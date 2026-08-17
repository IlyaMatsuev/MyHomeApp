import Foundation
import Testing
@testable import MyHomeApp

struct UserDefaultsMediaSettingsPersistenceTests {
    private let defaults: UserDefaults
    private let suiteName: String
    private let persistence: UserDefaultsMediaSettingsPersistence

    private let settings = MediaSettings(enabled: true, server: Server(.http, "media.home:8080", label: "Media"))

    init() throws {
        suiteName = "com.myhome.tests.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        persistence = UserDefaultsMediaSettingsPersistence(key: "test.media.settings", defaults: defaults)
    }

    @Test
    func loadReturnsNilWhenNothingPersisted() throws {
        #expect(try persistence.load() == nil)
    }

    @Test
    func saveThenLoadRoundTripsTheSettings() throws {
        try persistence.save(settings)

        #expect(try persistence.load() == settings)
    }

    @Test
    func saveOverwritesThePreviousValue() throws {
        try persistence.save(settings)
        let updated = MediaSettings(enabled: false, server: Server(.https, "media.example.com"))

        try persistence.save(updated)

        #expect(try persistence.load() == updated)
    }

    @Test
    func clearRemovesThePersistedValue() throws {
        try persistence.save(settings)

        try persistence.clear()

        #expect(try persistence.load() == nil)
    }

    @Test
    func loadThrowsForCorruptedData() {
        defaults.set(Data("not json".utf8), forKey: "test.media.settings")

        #expect(throws: MediaError.self) {
            try persistence.load()
        }
    }
}
