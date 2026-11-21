import Foundation
import Testing
@testable import MyHomeApp

/// Runs against the real (simulator) Keychain, under a service name unique to each test.
struct KeychainServerConfigPersistenceTests {
    private let keychain: KeychainItem
    private let legacy: InMemoryServerConfigPersistence
    private let persistence: KeychainServerConfigPersistence

    init() {
        keychain = KeychainItem(service: "com.myhome.tests.\(UUID().uuidString)", account: "servers")
        legacy = InMemoryServerConfigPersistence()
        persistence = KeychainServerConfigPersistence(keychain: keychain, legacy: legacy)
    }

    // MARK: - load() / save()

    @Test
    func loadReturnsNilWhenNothingPersisted() throws {
        #expect(try persistence.load() == nil)
    }

    @Test
    func saveThenLoadRoundTripsServersWithHeaders() throws {
        defer { try? keychain.delete() }
        let servers = [
            Server(.http, "192.168.1.10:8080", remote: false),
            Server(
                .https,
                "home.example.com",
                remote: true,
                headers: [ServerHeader(name: "X-Proxy-Authorization", value: "token")]
            )
        ]

        try persistence.save(servers)

        #expect(try persistence.load() == servers)
    }

    @Test
    func saveDoesNotWriteToLegacyStore() throws {
        defer { try? keychain.delete() }

        try persistence.save([Server(.http, "hub.local")])

        #expect(try legacy.load() == nil)
    }

    @Test
    func loadThrowsDecodingErrorForCorruptData() throws {
        defer { try? keychain.delete() }
        try keychain.write(Data("not-json".utf8))

        #expect(throws: ServerConfigError.self) {
            try persistence.load()
        }
    }

    // MARK: - load() — legacy migration

    @Test
    func loadMovesLegacyServersToKeychain() throws {
        defer { try? keychain.delete() }
        let servers = [Server(.http, "hub.local", label: "Hub")]
        try legacy.save(servers)

        let loaded = try persistence.load()

        #expect(loaded == servers)
        #expect(try legacy.load() == nil)
        #expect(try keychain.read() != nil)
    }

    @Test
    func loadAfterMigrationReadsFromKeychain() throws {
        defer { try? keychain.delete() }
        let servers = [Server(.http, "hub.local", label: "Hub")]
        try legacy.save(servers)
        _ = try persistence.load()

        #expect(try persistence.load() == servers)
    }

    @Test
    func loadPrefersKeychainOverLegacy() throws {
        defer { try? keychain.delete() }
        let current = [Server(.https, "home.example.com")]
        try persistence.save(current)
        try legacy.save([Server(.http, "stale.local")])

        #expect(try persistence.load() == current)
    }

    // MARK: - clear()

    @Test
    func clearRemovesKeychainAndLegacyServers() throws {
        try persistence.save([Server(.http, "hub.local")])
        try legacy.save([Server(.http, "stale.local")])

        try persistence.clear()

        #expect(try keychain.read() == nil)
        #expect(try legacy.load() == nil)
    }
}
