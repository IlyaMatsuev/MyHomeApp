import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct ServerConfigStoreTests {
    private let persistence: StubServerConfigPersistence
    private let service: ServerConfigService
    private let store: ServerConfigStore

    init() {
        persistence = StubServerConfigPersistence()
        service = StubServerConfigService()
        store = ServerConfigStore(persistence: persistence, service: service)
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
    func saveEmptyThrowsAnError() async throws {
        await #expect(throws: ServerConfigError.emptyList) {
            try await store.save([])
        }
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

    // MARK: - selectedServer

    @Test
    func initialSelectedServerIsNil() {
        #expect(store.selectedServer == nil)
    }

    @Test
    func loadPicksFirstServerAsSelected() async {
        let first = Server(.http, "hub.local:8080", remote: false, label: "Home")
        let second = Server(.https, "remote.example.com", remote: true, label: "Cottage")
        persistence.loadResult = .success([first, second])

        await store.load()

        #expect(store.selectedServer == first)
    }

    @Test
    func loadWhenUnconfiguredLeavesSelectionNil() async {
        persistence.loadResult = .success(nil)

        await store.load()

        #expect(store.selectedServer == nil)
    }

    @Test
    func selectChangesSelectedServer() async throws {
        let first = Server(.http, "hub.local:8080", remote: false, label: "Home")
        let second = Server(.https, "remote.example.com", remote: true, label: "Cottage")
        try await store.save([first, second])

        store.select(second)

        #expect(store.selectedServer == second)
    }

    @Test
    func selectIgnoresUnknownServer() async throws {
        let known = Server(.http, "hub.local:8080", remote: false, label: "Home")
        try await store.save([known])
        let stranger = Server(.http, "stranger.local", remote: false, label: "Stranger")

        store.select(stranger)

        #expect(store.selectedServer == known)
    }

    @Test
    func selectNilIsNoOp() async throws {
        let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
        try await store.save([server])

        store.select(nil)

        #expect(store.selectedServer == server)
    }

    @Test
    func savePreservesSelectionWhenStillPresent() async throws {
        let first = Server(.http, "hub.local:8080", remote: false, label: "Home")
        let second = Server(.https, "remote.example.com", remote: true, label: "Cottage")
        try await store.save([first, second])
        store.select(second)

        try await store.save([first, second])

        #expect(store.selectedServer == second)
    }

    @Test
    func saveResetsSelectionWhenRemoved() async throws {
        let first = Server(.http, "hub.local:8080", remote: false, label: "Home")
        let second = Server(.https, "remote.example.com", remote: true, label: "Cottage")
        try await store.save([first, second])
        store.select(second)

        try await store.save([first])

        #expect(store.selectedServer == first)
    }

    @Test
    func clearResetsSelection() async throws {
        let server = Server(.http, "hub.local:8080", remote: false, label: "Home")
        try await store.save([server])

        try await store.clear()

        #expect(store.selectedServer == nil)
    }
}
