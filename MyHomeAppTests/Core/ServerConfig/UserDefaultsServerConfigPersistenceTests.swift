import Foundation
import Testing
@testable import MyHomeApp

struct UserDefaultsServerConfigPersistenceTests {
    private struct StorageError: Error {}

    private static let key = "test.servers"
    private static let home = Server(.http, "192.168.1.10:8080", remote: false)
    private static let cabin = Server(.https, "home.example.com", remote: true)
    private static let secret = ServerHeader(name: "X-Proxy-Key", value: "s3cr3t")

    private let defaults: UserDefaults
    private let storage: StubSecretStorage
    private let persistence: UserDefaultsServerConfigPersistence

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "com.myhome.tests.\(UUID().uuidString)"))
        storage = StubSecretStorage()
        persistence = UserDefaultsServerConfigPersistence(headersStorage: storage, key: Self.key, defaults: defaults)
    }

    // MARK: - round trip

    @Test
    func loadReturnsNilWhenNothingPersisted() throws {
        #expect(try persistence.load() == nil)
    }

    @Test
    func saveThenLoadRoundTripsTheServersWithTheirOwnHeaders() throws {
        let servers = [
            Self.home.withHeaders(Self.secret, ServerHeader(name: "X-Tenant", value: "home")),
            Self.cabin.withHeaders(ServerHeader(name: "X-Proxy-Key", value: "other"))
        ]

        try persistence.save(servers)

        #expect(try persistence.load() == servers)
    }

    @Test
    func saveOverwritesPreviousValue() throws {
        try persistence.save([Self.home])

        try persistence.save([Self.cabin])

        #expect(try persistence.load() == [Self.cabin])
    }

    @Test
    func loadReadsListSavedBeforeHeadersExisted() throws {
        let legacy = #"[{"label":"192.168.1.10:8080","scheme":"http","address":"192.168.1.10:8080","remote":false}]"#
        defaults.set(Data(legacy.utf8), forKey: Self.key)

        #expect(try persistence.load() == [Self.home])
    }

    // MARK: - header storage

    @Test
    func saveKeepsHeadersOutOfDefaults() throws {
        try persistence.save([Self.home.withHeaders(Self.secret)])

        let data = try #require(defaults.data(forKey: Self.key))
        let raw = try #require(String(data: data, encoding: .utf8))
        #expect(!raw.contains(Self.secret.value))
        #expect(!raw.contains(Self.secret.name))
    }

    @Test
    func saveAfterAddressChangeLeavesNoOrphanHeaders() throws {
        var server = Self.home.withHeaders(Self.secret)
        try persistence.save([server])
        server.address = "hub.local"

        try persistence.save([server])

        let data = try #require(storage.data)
        let stored = try JSONDecoder().decode([Server.ID: [ServerHeader]].self, from: data)
        #expect(stored == ["hub.local": [Self.secret]])
    }

    @Test
    func saveWithoutAnyHeadersDeletesStoredItem() throws {
        try persistence.save([Self.home.withHeaders(Self.secret)])

        try persistence.save([Self.home])

        #expect(storage.data == nil)
    }

    // MARK: - unreadable headers

    @Test
    func loadReturnsServersWithoutHeadersWhenTheyCannotBeRead() throws {
        try persistence.save([Self.home.withHeaders(Self.secret), Self.cabin])
        storage.readError = StorageError()

        #expect(try persistence.load() == [Self.home, Self.cabin])
    }

    @Test
    func corruptHeadersLoadAsEmptyAndDoNotBlockSave() throws {
        try persistence.save([Self.home.withHeaders(Self.secret)])
        storage.data = Data("not-json".utf8)

        #expect(try persistence.load() == [Self.home])

        let updated = [Self.home.withHeaders(Self.secret)]
        try persistence.save(updated)
        #expect(try persistence.load() == updated)
    }

    // MARK: - failed header writes

    @Test
    func saveWhenHeadersWriteFailsKeepsPreviousList() throws {
        let previous = [Self.home.withHeaders(Self.secret)]
        try persistence.save(previous)
        storage.writeError = StorageError()

        #expect(throws: StorageError.self) {
            try persistence.save([Self.cabin.withHeaders(Self.secret)])
        }
        #expect(try persistence.load() == previous)
    }

    @Test
    func saveWhenHeadersDeleteFailsKeepsPreviousList() throws {
        let previous = [Self.home.withHeaders(Self.secret)]
        try persistence.save(previous)
        storage.deleteError = StorageError()

        #expect(throws: StorageError.self) {
            try persistence.save([Self.cabin])
        }
        #expect(try persistence.load() == previous)
    }

    // MARK: - clear()

    @Test
    func clearRemovesListAndHeaders() throws {
        try persistence.save([Self.home.withHeaders(Self.secret)])

        try persistence.clear()

        #expect(try persistence.load() == nil)
        #expect(storage.data == nil)
    }
}
