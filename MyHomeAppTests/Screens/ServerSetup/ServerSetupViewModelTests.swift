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

    // MARK: - custom headers — editing

    @Test
    func draftServerStartsWithoutHeaders() {
        #expect(viewModel.draftServer.headers.isEmpty)
    }

    @Test
    func addDraftHeaderAppendsBlankHeader() throws {
        viewModel.showAddServerForm()

        viewModel.addDraftHeader()

        let header = try #require(viewModel.draftServer.headers.first)
        #expect(viewModel.draftServer.headers.count == 1)
        #expect(header.isBlank)
    }

    @Test
    func removeDraftHeadersRemovesAtOffsets() {
        viewModel.showAddServerForm()
        viewModel.draftServer.headers = [
            ServerHeader(name: "X-First", value: "1"),
            ServerHeader(name: "X-Second", value: "2")
        ]

        viewModel.removeDraftHeaders(at: IndexSet(integer: 0))

        #expect(viewModel.draftServer.headers.map(\.name) == ["X-Second"])
    }

    @Test
    func showAddServerFormDropsHeadersOfPreviousDraft() {
        viewModel.showEditServerForm(
            Server(.https, "home.example.com", label: "Cabin", headers: [ServerHeader(name: "X-Api-Key", value: "token")])
        )
        viewModel.closeServerForm()

        viewModel.showAddServerForm()

        #expect(viewModel.draftServer.headers.isEmpty)
    }

    // MARK: - custom headers — validation

    @Test
    func canSaveDraftIsFalseWithInvalidHeader() {
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        viewModel.draftServer.headers = [ServerHeader(name: "X Proxy", value: "token")]

        #expect(!viewModel.canSaveDraft)
    }

    @Test
    func canSaveDraftIgnoresBlankHeader() {
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        viewModel.addDraftHeader()

        #expect(viewModel.canSaveDraft)
    }

    @Test
    func headerNameErrorIsNilForBlankHeader() {
        #expect(viewModel.headerNameError(for: ServerHeader()) == nil)
    }

    @Test
    func headerNameErrorIsNilForValidName() {
        #expect(viewModel.headerNameError(for: ServerHeader(name: "X-Api-Key", value: "")) == nil)
    }

    @Test
    func headerNameErrorAsksForNameWhenOnlyValueIsSet() {
        #expect(viewModel.headerNameError(for: ServerHeader(name: "", value: "token")) == "Enter a header name.")
    }

    @Test
    func headerNameErrorFlagsInvalidCharacters() {
        let error = viewModel.headerNameError(for: ServerHeader(name: "X Proxy", value: "token"))
        #expect(error == "Use letters, digits and dashes, e.g. X-Api-Key.")
    }

    @Test
    func headerNameErrorFlagsReservedName() {
        let error = viewModel.headerNameError(for: ServerHeader(name: "Proxy-Authorization", value: "token"))
        #expect(error == "The app can't send this header. Use another name, e.g. X-Proxy-Authorization.")
    }

    @Test
    func headerNameErrorFlagsDuplicateName() throws {
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        viewModel.draftServer.headers = [
            ServerHeader(name: "X-Api-Key", value: "1"),
            ServerHeader(name: "x-api-key", value: "2")
        ]
        let duplicate = try #require(viewModel.draftServer.headers.last)

        #expect(viewModel.headerNameError(for: duplicate) == "This header is already in the list.")
        #expect(!viewModel.canSaveDraft)
    }

    @Test
    func headerValueErrorIsNilForBlankHeader() {
        #expect(viewModel.headerValueError(for: ServerHeader()) == nil)
    }

    @Test
    func headerValueErrorAsksForValueWhenOnlyNameIsSet() {
        #expect(viewModel.headerValueError(for: ServerHeader(name: "X-Api-Key", value: "")) == "Enter a header value.")
    }

    @Test
    func headerValueErrorIsNilForValidValue() {
        #expect(viewModel.headerValueError(for: ServerHeader(name: "X-Api-Key", value: "token")) == nil)
    }

    @Test
    func headerValueErrorFlagsLineBreaks() {
        let error = viewModel.headerValueError(for: ServerHeader(name: "X-Api-Key", value: "tok\nen"))
        #expect(error == "Use printable ASCII characters only.")
    }

    // MARK: - custom headers — saveDraft()

    @Test
    func saveDraftWithInvalidHeaderSetsHeadersErrorWithoutCallingService() async {
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "hub.home"
        viewModel.draftServer.headers = [ServerHeader(name: "", value: "token")]

        await viewModel.saveDraft()

        #expect(viewModel.servers.isEmpty)
        #expect(service.checkedServers.isEmpty)
        #expect(viewModel.draftErrorMessage == "Fix the custom headers in Advanced settings.")
    }

    @Test
    func saveDraftChecksReachabilityWithHeaders() async throws {
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "home.example.com"
        viewModel.draftServer.headers = [ServerHeader(name: "X-Proxy-Authorization", value: "token")]

        await viewModel.saveDraft()

        let checked = try #require(service.checkedServers.first)
        let header = try #require(checked.headers.first)
        #expect(checked.headers.count == 1)
        #expect(header.name == "X-Proxy-Authorization")
        #expect(header.value == "token")
    }

    @Test
    func saveDraftDropsBlankHeadersAndTrimsTheRest() async throws {
        service.isReachableResult = true
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "home.example.com"
        viewModel.draftServer.headers = [
            ServerHeader(name: " X-Proxy-Authorization ", value: "token\n"),
            ServerHeader()
        ]

        await viewModel.saveDraft()

        let added = try #require(viewModel.servers.first)
        let header = try #require(added.headers.first)
        #expect(added.headers.count == 1)
        #expect(header.name == "X-Proxy-Authorization")
        #expect(header.value == "token")
    }

    @Test
    func failedSaveDraftLeavesFormHeadersUntouched() async {
        service.isReachableResult = false
        viewModel.showAddServerForm()
        viewModel.draftServer.address = "home.example.com"
        let headers = [ServerHeader(name: " X-Proxy-Authorization ", value: "token"), ServerHeader()]
        viewModel.draftServer.headers = headers

        await viewModel.saveDraft()

        #expect(viewModel.draftErrorMessage == "Couldn't connect to the server.")
        #expect(viewModel.draftServer.headers == headers)
    }

    @Test
    func saveDraftWhileEditingReplacesHeaders() async throws {
        let original = Server(
            .https,
            "home.example.com",
            remote: true,
            label: "Cabin",
            headers: [ServerHeader(name: "X-Old", value: "old")]
        )
        viewModel.servers = [original]
        service.isReachableResult = true

        viewModel.showEditServerForm(original)
        viewModel.removeDraftHeaders(at: IndexSet(integer: 0))
        viewModel.addDraftHeader()
        viewModel.draftServer.headers[0].name = "X-New"
        viewModel.draftServer.headers[0].value = "new"

        await viewModel.saveDraft()

        let updated = try #require(viewModel.servers.first)
        let header = try #require(updated.headers.first)
        #expect(viewModel.servers.count == 1)
        #expect(updated.headers.count == 1)
        #expect(header.name == "X-New")
        #expect(header.value == "new")
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
