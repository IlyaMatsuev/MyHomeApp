import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct MediaManagerSettingsViewModelTests {
    private static let addressRequiredError = "Enter the Media Manager address. Example: 192.168.1.10:8080"
    private static let unreachableError = "Couldn't reach the Media Manager at this address."

    private let persistence: StubMediaSettingsPersistence
    private let store: MediaSettingsStore
    private let service: StubMediaService
    private let viewModel: MediaManagerSettingsViewModel

    init() {
        let persistence = StubMediaSettingsPersistence()
        let store = MediaSettingsStore(persistence: persistence)
        let service = StubMediaService()

        self.persistence = persistence
        self.store = store
        self.service = service
        self.viewModel = MediaManagerSettingsViewModel(store: store, service: service)
    }

    // MARK: - init

    @Test
    func draftStartsFromTheStoredSettings() {
        #expect(viewModel.draft == MediaSettings.disabled)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.saving == false)
    }

    // MARK: - canSave

    @Test
    func cannotSaveWhenEnabledWithoutAnAddress() {
        viewModel.draft.enabled = true

        #expect(viewModel.canSave == false)
    }

    @Test
    func canSaveWhenEnabledWithAnAddress() {
        viewModel.draft = MediaSettings(enabled: true, server: Server(.http, "media.home:8080"))

        #expect(viewModel.canSave)
    }

    @Test
    func canSaveWhenDisabledEvenWithoutAnAddress() {
        #expect(viewModel.canSave)
    }

    // MARK: - save()

    @Test
    func saveValidatesTheAddressAgainstTheHealthEndpoint() async throws {
        viewModel.draft = MediaSettings(enabled: true, server: Server(.http, "media.home:8080"))

        await viewModel.save()

        let checked = try #require(service.healthCalls.first)
        #expect(checked.address == "media.home:8080")
        #expect(viewModel.errorMessage == nil)
        #expect(store.settings.enabled)
        #expect(store.enabled)
        #expect(persistence.savedSettings.count == 1)
    }

    @Test
    func saveWithAnUnreachableAddressReportsAnErrorAndPersistsNothing() async {
        service.healthy = false
        viewModel.draft = MediaSettings(enabled: true, server: Server(.http, "media.home:8080"))

        await viewModel.save()

        #expect(viewModel.errorMessage == Self.unreachableError)
        #expect(persistence.savedSettings.isEmpty)
        #expect(store.enabled == false)
    }

    @Test
    func saveWithAnEmptyAddressAsksForOne() async {
        viewModel.draft.enabled = true

        await viewModel.save()

        #expect(viewModel.errorMessage == Self.addressRequiredError)
        #expect(service.healthCalls.isEmpty)
        #expect(persistence.savedSettings.isEmpty)
    }

    @Test
    func saveTrimsTheAddressBeforeValidating() async throws {
        viewModel.draft = MediaSettings(enabled: true, server: Server(.http, "media.home:8080"))
        viewModel.draft.server.address = "  media.home:8080  "

        await viewModel.save()

        let checked = try #require(service.healthCalls.first)
        #expect(checked.address == "media.home:8080")
        #expect(store.settings.server.address == "media.home:8080")
    }

    @Test
    func savingWhileDisabledSkipsTheHealthCheck() async {
        viewModel.draft = MediaSettings(enabled: false, server: Server(.http, ""))

        await viewModel.save()

        #expect(service.healthCalls.isEmpty)
        #expect(persistence.savedSettings.count == 1)
        #expect(store.enabled == false)
    }

    @Test
    func saveWhenPersistenceFailsReportsAnError() async {
        struct SaveError: Error {}
        persistence.saveError = SaveError()
        viewModel.draft = MediaSettings(enabled: true, server: Server(.http, "media.home:8080"))

        await viewModel.save()

        #expect(viewModel.errorMessage == "Couldn't save the Media Manager settings.")
        #expect(store.enabled == false)
    }

    // MARK: - draft edits

    @Test
    func editingTheDraftClearsThePreviousError() async {
        viewModel.draft.enabled = true
        await viewModel.save()
        #expect(viewModel.errorMessage == Self.addressRequiredError)

        viewModel.draft.server.address = "media.home:8080"

        #expect(viewModel.errorMessage == nil)
    }
}
