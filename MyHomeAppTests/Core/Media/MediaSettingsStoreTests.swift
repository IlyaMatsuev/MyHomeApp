import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct MediaSettingsStoreTests {
    private let persistence: StubMediaSettingsPersistence
    private let store: MediaSettingsStore

    private let configured = MediaSettings(enabled: true, server: Server(.http, "media.home:8080"))

    init() {
        persistence = StubMediaSettingsPersistence()
        store = MediaSettingsStore(persistence: persistence)
    }

    // MARK: - init

    @Test
    func startsDisabled() {
        #expect(store.settings == .disabled)
        #expect(store.enabled == false)
        #expect(store.server == nil)
    }

    // MARK: - load()

    @Test
    func loadWithPersistedSettingsRestoresThem() async {
        persistence.loadResult = .success(configured)

        await store.load()

        #expect(store.settings == configured)
        #expect(store.enabled)
        #expect(store.server == configured.server)
    }

    @Test
    func loadWithNothingPersistedKeepsTheIntegrationOff() async {
        persistence.loadResult = .success(nil)

        await store.load()

        #expect(store.settings == .disabled)
        #expect(store.enabled == false)
    }

    @Test
    func loadWhenPersistenceThrowsFallsBackToDisabled() async {
        struct LoadError: Error {}
        persistence.loadResult = .failure(LoadError())

        await store.load()

        #expect(store.settings == .disabled)
        #expect(store.enabled == false)
    }

    // MARK: - save()

    @Test
    func savePersistsAndPublishesTheSettings() async throws {
        try await store.save(configured)

        #expect(persistence.savedSettings == [configured])
        #expect(store.settings == configured)
        #expect(store.enabled)
    }

    @Test
    func saveWhenPersistenceThrowsKeepsThePreviousSettings() async {
        struct SaveError: Error {}
        persistence.saveError = SaveError()

        await #expect(throws: SaveError.self) {
            try await store.save(configured)
        }
        #expect(store.settings == .disabled)
    }

    // MARK: - server

    @Test
    func serverIsNilWhenTheAddressIsNotUsable() async throws {
        try await store.save(MediaSettings(enabled: true, server: Server(.http, "")))

        #expect(store.server == nil)
        #expect(store.enabled == false)
    }

    @Test
    func serverIsNilWhenTheIntegrationIsOff() async throws {
        try await store.save(MediaSettings(enabled: false, server: Server(.http, "media.home:8080")))

        #expect(store.server == nil)
    }
}
