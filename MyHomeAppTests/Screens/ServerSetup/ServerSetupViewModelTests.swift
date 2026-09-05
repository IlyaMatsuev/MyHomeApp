import Foundation
import Testing
@testable import MyHomeApp

// swiftlint:disable file_length

@MainActor
// swiftlint:disable:next type_body_length
struct ServerSetupViewModelTests {
    private let persistence: StubServerConfigPersistence
    private let store: ServerConfigStore
    private let service: StubServerConfigService
    private let viewModel: ServerSetupViewModel

    init() {
        persistence = StubServerConfigPersistence()
        service = StubServerConfigService()
        store = ServerConfigStore(persistence: persistence, service: service)
        viewModel = ServerSetupViewModel(mode: .initialSetup, store: store)
    }

    // MARK: - default state

    @Test
    func defaultsToEmptyListAndClosedForm() {
        #expect(viewModel.servers.isEmpty)
        #expect(!viewModel.isServerFormOpen)
        #expect(!viewModel.addingNewServer)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.draftErrorMessage == nil)
        #expect(!viewModel.loading)
    }

    @Test
    func draftServerStartsWithTemplateValues() {
        #expect(viewModel.draftServer.scheme == .https)
        #expect(viewModel.draftServer.address == "")
        #expect(viewModel.draftServer.label == "Home")
        #expect(!viewModel.draftServer.remote)
    }

    @Test
    func initSeedsServersFromStore() async {
        let seeded = [Server(.https, "home.example.com", remote: true, label: "Home")]
        persistence.loadResult = .success(seeded)
        await store.load()

        let viewModel = ServerSetupViewModel(mode: .initialSetup, store: store)

        #expect(viewModel.servers == seeded)
    }

    // MARK: - mode

    @Test
    func initSetsInitialSetupMode() {
        #expect(viewModel.mode == .initialSetup)
    }

    @Test
    func initSetsEditModeWhenRequested() {
        let editingViewModel = ServerSetupViewModel(mode: .edit, store: store)

        #expect(editingViewModel.mode == .edit)
    }

    // MARK: - showAddServerForm()

    @Test
    func showAddServerFormOpensSheetAndResetsDraftToTemplate() {
        viewModel.draftServer = Server(.http, "leftover", remote: true, label: "Stale")

        viewModel.showAddServerForm()

        #expect(viewModel.isServerFormOpen)
        #expect(viewModel.addingNewServer)
        #expect(viewModel.draftServer.scheme == .https)
        #expect(viewModel.draftServer.address == "")
        #expect(viewModel.draftServer.label == "Home")
        #expect(!viewModel.draftServer.remote)
    }

    // MARK: - showEditServerForm()

    @Test
    func showEditServerFormOpensSheetWithProvidedServer() {
        let server = Server(.https, "home.example.com", remote: true, label: "Cabin")

        viewModel.showEditServerForm(server)

        #expect(viewModel.isServerFormOpen)
        #expect(!viewModel.addingNewServer)
        #expect(viewModel.draftServer == server)
    }

    // MARK: - closeServerForm()

    @Test
    func closeServerFormHidesSheetAndClearsTransientState() {
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"

        viewModel.closeServerForm()

        #expect(!viewModel.isServerFormOpen)
        #expect(!viewModel.addingNewServer)
        #expect(viewModel.draftErrorMessage == nil)
        #expect(!viewModel.loading)
    }

    /// Regression test: closing the form must NOT reset `draftServer`. Resetting it in the
    /// same tick the cover starts animating away caused the sheet's bindings to flash the
    /// template defaults during dismissal.
    @Test
    func closeServerFormPreservesDraftServerToAvoidDismissFlash() {
        let edited = Server(.https, "home.example.com", remote: true, label: "Cabin")
        viewModel.showEditServerForm(edited)

        viewModel.closeServerForm()

        #expect(viewModel.draftServer == edited)
    }

    @Test
    func showAddServerFormAfterCloseReseedsDraft() {
        viewModel.showEditServerForm(Server(.http, "hub.local", label: "Hub"))
        viewModel.closeServerForm()

        viewModel.showAddServerForm()

        #expect(viewModel.draftServer.scheme == .https)
        #expect(viewModel.draftServer.address == "")
        #expect(viewModel.draftServer.label == "Home")
        #expect(!viewModel.draftServer.remote)
    }

    // MARK: - canSaveDraft

    @Test
    func canSaveDraftIsFalseWhenFormClosedEvenIfDraftValid() {
        viewModel.draftServer.address = "hub.home"
        #expect(viewModel.draftServer.valid)
        #expect(!viewModel.canSaveDraft)
    }

    @Test
    func canSaveDraftIsFalseWhenDraftInvalid() {
        viewModel.showAddServerForm()
        viewModel.draftServer.address = ""
        #expect(!viewModel.canSaveDraft)
    }

    @Test
    func canSaveDraftIsTrueWhenFormOpenAndDraftValid() {
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        #expect(viewModel.canSaveDraft)
    }

    // MARK: - canContinue

    @Test
    func canContinueIsFalseForEmptyList() {
        #expect(!viewModel.canContinue)
    }

    @Test
    func canContinueIsFalseWhileFormOpen() async {
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        await viewModel.saveDraft()

        viewModel.showAddServerForm()

        #expect(!viewModel.canContinue)
    }

    @Test
    func canContinueIsTrueWithAtLeastOneServerAndClosedForm() async {
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        await viewModel.saveDraft()

        #expect(viewModel.canContinue)
    }

    // MARK: - saveDraft() — validation

    @Test
    func saveDraftWithoutOpenFormSetsInvalidAddressError() async {
        viewModel.draftServer.address = "hub.home"

        await viewModel.saveDraft()

        #expect(viewModel.servers.isEmpty)
        #expect(service.checkedServers.isEmpty)
        #expect(viewModel.draftErrorMessage == "Enter a valid address. Example: 192.168.1.10:8080")
    }

    @Test
    func saveDraftWithInvalidAddressSetsInvalidAddressErrorWithoutCallingService() async {
        viewModel.showAddServerForm()
        viewModel.draftServer.address = ""

        await viewModel.saveDraft()

        #expect(viewModel.servers.isEmpty)
        #expect(service.checkedServers.isEmpty)
        #expect(viewModel.draftErrorMessage == "Enter a valid address. Example: 192.168.1.10:8080")
    }

    // MARK: - saveDraft() — duplicate checks (adding only)

    @Test
    func saveDraftRejectsDuplicateLabelWhenAdding() async {
        viewModel.servers = [Server(.http, "hub.local", remote: false, label: "Home")]
        service.isReachableResult = true

        viewModel.showAddServerForm()
        viewModel.draftServer.address = "second.host"

        await viewModel.saveDraft()

        #expect(viewModel.servers.count == 1)
        #expect(viewModel.draftErrorMessage == "You already have a server with the same label.")
        #expect(service.checkedServers.isEmpty)
    }

    @Test
    func saveDraftRejectsDuplicateAddressWhenAdding() async {
        viewModel.servers = [Server(.http, "hub.local", remote: false, label: "Hub")]
        service.isReachableResult = true

        viewModel.showAddServerForm()
        viewModel.draftServer.label = "Different"
        viewModel.draftServer.address = "hub.local"

        await viewModel.saveDraft()

        #expect(viewModel.servers.count == 1)
        #expect(viewModel.draftErrorMessage == "You already have a server with the same address.")
        #expect(service.checkedServers.isEmpty)
    }

    @Test
    func saveDraftWhileEditingAllowsSavingUnchangedServer() async {
        let original = Server(.http, "hub.local", remote: false, label: "Hub")
        viewModel.servers = [original]
        service.isReachableResult = true

        viewModel.showEditServerForm(original)

        await viewModel.saveDraft()

        #expect(viewModel.servers.count == 1)
        #expect(viewModel.draftErrorMessage == nil)
    }

    @Test
    func saveDraftWhileEditingRejectsLabelThatCollidesWithAnotherServer() async {
        let edited = Server(.http, "hub.local", remote: false, label: "Hub")
        let other = Server(.https, "home.example.com", remote: true, label: "Cabin")
        viewModel.servers = [edited, other]
        service.isReachableResult = true

        viewModel.showEditServerForm(edited)
        viewModel.draftServer.label = "Cabin"

        await viewModel.saveDraft()

        #expect(viewModel.servers == [edited, other])
        #expect(viewModel.draftErrorMessage == "You already have a server with the same label.")
        #expect(service.checkedServers.isEmpty)
    }

    @Test
    func saveDraftWhileEditingRejectsAddressThatCollidesWithAnotherServer() async {
        let edited = Server(.http, "hub.local", remote: false, label: "Hub")
        let other = Server(.https, "home.example.com", remote: true, label: "Cabin")
        viewModel.servers = [edited, other]
        service.isReachableResult = true

        viewModel.showEditServerForm(edited)
        viewModel.draftServer.address = "home.example.com"

        await viewModel.saveDraft()

        #expect(viewModel.servers == [edited, other])
        #expect(viewModel.draftErrorMessage == "You already have a server with the same address.")
        #expect(service.checkedServers.isEmpty)
    }

    @Test
    func saveDraftWhileEditingReplacesOriginalEvenWhenAddressChanges() async throws {
        let original = Server(.http, "hub.local", remote: false, label: "Hub")
        viewModel.servers = [original]
        service.isReachableResult = true

        viewModel.showEditServerForm(original)
        viewModel.draftServer.address = "hub.home"

        await viewModel.saveDraft()

        let updated = try #require(viewModel.servers.first)
        #expect(viewModel.servers.count == 1)
        #expect(updated.address == "hub.home")
        #expect(updated.label == "Hub")
    }

    // MARK: - saveDraft() — reachability

    @Test
    func saveDraftAppendsServerWhenReachable() async throws {
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.scheme = .http
        viewModel.draftServer.address = "hub.home"
        viewModel.draftServer.label = "Hub"

        await viewModel.saveDraft()

        let added = try #require(viewModel.servers.first)
        #expect(viewModel.servers.count == 1)
        #expect(added.scheme == .http)
        #expect(added.address == "hub.home")
        #expect(added.label == "Hub")
        #expect(!added.remote)
        #expect(!viewModel.isServerFormOpen)
        #expect(viewModel.draftErrorMessage == nil)
        #expect(service.checkedServers.count == 1)
    }

    @Test
    func saveDraftSetsErrorAndKeepsSheetOpenWhenUnreachable() async {
        service.isReachableResult = false
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "unreachable.local"

        await viewModel.saveDraft()

        #expect(viewModel.servers.isEmpty)
        #expect(viewModel.draftErrorMessage == "Couldn't connect to the server.")
        #expect(viewModel.isServerFormOpen)
        #expect(!viewModel.loading)
    }

    @Test
    func saveDraftWhileEditingReplacesServerInPlaceWhenReachable() async throws {
        let original = Server(.http, "hub.local", remote: false, label: "Hub")
        viewModel.servers = [original]
        service.isReachableResult = true

        viewModel.showEditServerForm(original)
        viewModel.draftServer.scheme = .https
        viewModel.draftServer.label = "Hub Renamed"
        viewModel.draftServer.remote = true

        await viewModel.saveDraft()

        let updated = try #require(viewModel.servers.first)
        #expect(viewModel.servers.count == 1)
        #expect(updated.id == original.id)
        #expect(updated.scheme == .https)
        #expect(updated.label == "Hub Renamed")
        #expect(updated.remote)
        #expect(!viewModel.isServerFormOpen)
    }

    @Test
    func saveDraftWhileEditingKeepsOriginalWhenUnreachable() async {
        let original = Server(.http, "hub.local", remote: false, label: "Hub")
        viewModel.servers = [original]
        service.isReachableResult = false

        viewModel.showEditServerForm(original)
        viewModel.draftServer.scheme = .https

        await viewModel.saveDraft()

        #expect(viewModel.servers == [original])
        #expect(viewModel.draftErrorMessage == "Couldn't connect to the server.")
        #expect(viewModel.isServerFormOpen)
    }

    @Test
    func saveDraftClearsLoadingAfterCompletion() async {
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"

        await viewModel.saveDraft()

        #expect(!viewModel.loading)
    }

    // MARK: - draftErrorMessage clearing

    @Test
    func mutatingDraftServerClearsDraftError() async {
        service.isReachableResult = false
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "broken.local"
        await viewModel.saveDraft()
        #expect(viewModel.draftErrorMessage != nil)

        viewModel.draftServer.address = "hub.home"

        #expect(viewModel.draftErrorMessage == nil)
    }

    // MARK: - removeServer(at:)

    @Test
    func removeServerRemovesAtOffsets() {
        viewModel.servers = [
            Server(.http, "first.host", label: "First"),
            Server(.http, "second.host", label: "Second")
        ]

        viewModel.removeServer(at: IndexSet(integer: 0))

        #expect(viewModel.servers.count == 1)
        #expect(viewModel.servers[0].address == "second.host")
    }

    @Test
    func removeServerClearsErrorMessage() async {
        struct SaveError: LocalizedError { var errorDescription: String? { "save failed" } }
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        await viewModel.saveDraft()
        persistence.saveError = SaveError()
        await viewModel.continueSetup()
        #expect(viewModel.errorMessage != nil)

        viewModel.removeServer(at: IndexSet(integer: 0))

        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - continueSetup()

    @Test
    func continueSetupPersistsServersAndConfiguresStore() async {
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        await viewModel.saveDraft()

        await viewModel.continueSetup()

        let expected = viewModel.servers
        #expect(persistence.savedServers == [expected])
        #expect(store.state == .configured(expected))
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.loading)
    }

    @Test
    func continueSetupWithEmptyListDoesNothing() async {
        await viewModel.continueSetup()

        #expect(persistence.savedServers.isEmpty)
        #expect(store.state == .loading)
    }

    @Test
    func continueSetupOnFailureSetsErrorMessage() async {
        struct SaveError: LocalizedError { var errorDescription: String? { "save failed" } }
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        await viewModel.saveDraft()
        persistence.saveError = SaveError()

        await viewModel.continueSetup()

        #expect(viewModel.errorMessage == "save failed")
        #expect(!viewModel.loading)
    }
}
