import Foundation
import Testing
@testable import SmartHomeAppIOS

struct UserDefaultsServerConfigPersistenceTests {
    private let defaults: UserDefaults
    private let suiteName: String
    private let persistence: UserDefaultsServerConfigPersistence

    init() throws {
        suiteName = "com.smarthome.tests.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        persistence = UserDefaultsServerConfigPersistence(key: "test.servers", defaults: defaults)
    }

    @Test
    func loadReturnsNilWhenNothingPersisted() throws {
        #expect(try persistence.load() == nil)
    }

    @Test
    func saveThenLoadRoundTripsTheServers() throws {
        let servers = [
            Server(.http, "192.168.1.10:8080", remote: false),
            Server(.https, "home.example.com", remote: true)
        ]

        try persistence.save(servers)

        #expect(try persistence.load() == servers)
    }

    @Test
    func saveOverwritesPreviousValue() throws {
        try persistence.save([Server(.http, "hub.local", remote: false)])
        let updated = [Server(.https, "home.example.com", remote: true)]

        try persistence.save(updated)

        #expect(try persistence.load() == updated)
    }

    @Test
    func clearRemovesPersistedValue() throws {
        try persistence.save([Server(.http, "hub.local", remote: false)])

        try persistence.clear()

        #expect(try persistence.load() == nil)
    }
}
