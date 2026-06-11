import Foundation
import Testing
@testable import SmartHomeAppIOS

@MainActor
struct ServerConfigStoreTests {
    private let persistence: StubServerConfigPersistence
    private let store: ServerConfigStore

    init() {
        persistence = StubServerConfigPersistence()
        store = ServerConfigStore(persistence: persistence)
    }

    // MARK: - init

    @Test
    func initialStateIsLoading() {
        #expect(store.state == .loading)
        #expect(store.servers.isEmpty)
    }

    // MARK: - load()

    @Test
    func loadWithPersistedServersBecomesConfigured() async throws {
        let servers = [Server(.http, "hub.local:8080", remote: false)]
        persistence.loadResult = .success(servers)

        await store.load()

        #expect(store.state == .configured(servers))
        #expect(store.servers == servers)
    }

    @Test
    func loadWithEmptyArrayBecomesUnconfigured() async {
        persistence.loadResult = .success([])

        await store.load()

        #expect(store.state == .unconfigured)
        #expect(store.servers.isEmpty)
    }

    @Test
    func loadWithNilBecomesUnconfigured() async {
        persistence.loadResult = .success(nil)

        await store.load()

        #expect(store.state == .unconfigured)
    }

    @Test
    func loadWhenPersistenceThrowsBecomesUnconfigured() async {
        struct LoadError: Error {}
        persistence.loadResult = .failure(LoadError())

        await store.load()

        #expect(store.state == .unconfigured)
    }

    // MARK: - save()

    @Test
    func saveNonEmptyArrayPersistsAndBecomesConfigured() async throws {
        let servers = [Server(.https, "home.example.com", remote: true)]

        try await store.save(servers)

        #expect(store.state == .configured(servers))
        #expect(persistence.savedServers == [servers])
    }

    @Test
    func saveEmptyArrayBecomesUnconfigured() async throws {
        try await store.save([])

        #expect(store.state == .unconfigured)
        #expect(persistence.savedServers == [[]])
    }

    @Test
    func saveOnFailureThrowsAndLeavesStateUnchanged() async {
        struct SaveError: Error {}
        persistence.saveError = SaveError()
        let servers = [Server(.http, "hub.local", remote: false)]

        await #expect(throws: SaveError.self) {
            try await store.save(servers)
        }
        #expect(store.state == .loading)
    }

    // MARK: - clear()

    @Test
    func clearBecomesUnconfigured() async throws {
        try await store.save([Server(.http, "hub.local", remote: false)])

        try await store.clear()

        #expect(store.state == .unconfigured)
        #expect(persistence.clearCallCount == 1)
    }
}
