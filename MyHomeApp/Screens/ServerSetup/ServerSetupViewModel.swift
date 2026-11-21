import Foundation
import Observation

@Observable
@MainActor
final class ServerSetupViewModel {
    private static let duplicateLabelError = "You already have a server with the same label."
    private static let duplicateAddressError = "You already have a server with the same address."
    private static let invalidHostAddressError = "Enter a valid address. Example: 192.168.1.10:8080"
    private static let serverUnreachableError = "Couldn't connect to the server."
    private static let invalidHeadersError = "Fix the custom headers in Advanced settings."
    private static let headerNameRequiredError = "Enter a header name."
    private static let invalidHeaderNameError = "Use letters, digits and dashes, e.g. X-Api-Key."
    private static let reservedHeaderNameError = "The app can't send this header. Use another name, e.g. X-Proxy-Authorization."
    private static let duplicateHeaderNameError = "This header is already in the list."
    private static let headerValueRequiredError = "Enter a header value."
    private static let invalidHeaderValueError = "Use printable ASCII characters only."
    private static let defaultLabel = "Home"
    private static let serverTemplate = Server(.https, "", remote: false, label: defaultLabel)

    private let store: ServerConfigStore

    private(set) var errorMessage: String?
    private(set) var draftErrorMessage: String?
    private(set) var loading: Bool = false

    private var editingServerId: String?

    var mode: ServerSetupMode
    var servers: [Server] = []

    var draftServer: Server {
        didSet { draftErrorMessage = nil }
    }

    var isServerFormOpen: Bool = false

    var addingNewServer: Bool {
        isServerFormOpen && editingServerId == nil
    }

    var canSaveDraft: Bool {
        !loading && isServerFormOpen && draftServer.valid == true
    }

    var canContinue: Bool {
        !loading && !isServerFormOpen && !servers.isEmpty
    }

    init(mode: ServerSetupMode, store: ServerConfigStore) {
        self.mode = mode
        self.store = store
        self.servers = store.servers
        self.draftServer = Self.serverTemplate
    }

    func showAddServerForm() {
        draftServer = Self.serverTemplate
        isServerFormOpen = true
        editingServerId = nil
    }

    func showEditServerForm(_ server: Server) {
        draftServer = server
        isServerFormOpen = true
        editingServerId = server.id
    }

    func closeServerForm() {
        isServerFormOpen = false
        editingServerId = nil
        draftErrorMessage = nil
        loading = false
    }

    func removeServer(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where servers.indices.contains(index) {
            servers.remove(at: index)
        }
        errorMessage = nil
    }

    func addDraftHeader() {
        draftServer.headers.append(ServerHeader())
    }

    func removeDraftHeaders(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where draftServer.headers.indices.contains(index) {
            draftServer.headers.remove(at: index)
        }
    }

    func headerNameError(for header: ServerHeader) -> String? {
        guard !header.isBlank else { return nil }
        if header.name.isBlank {
            return Self.headerNameRequiredError
        }
        if !header.hasValidName {
            return Self.invalidHeaderNameError
        }
        if header.hasReservedName {
            return Self.reservedHeaderNameError
        }
        if draftServer.duplicateHeaderNames.contains(header.normalizedName) {
            return Self.duplicateHeaderNameError
        }
        return nil
    }

    func headerValueError(for header: ServerHeader) -> String? {
        guard !header.isBlank, !header.hasValidValue else { return nil }
        return header.value.isBlank ? Self.headerValueRequiredError : Self.invalidHeaderValueError
    }

    func saveDraft() async {
        guard canSaveDraft else {
            return draftErrorMessage = draftServer.hasValidHeaders ? Self.invalidHostAddressError : Self.invalidHeadersError
        }

        errorMessage = nil
        loading = true
        defer { loading = false }

        // Saved without the blank rows, but the form keeps them in case the save fails.
        var server = draftServer
        server.headers = server.headers.filter { !$0.isBlank }.map(\.trimmed)

        if servers.contains(where: { $0.label == server.label && $0.id != editingServerId }) {
            return draftErrorMessage = Self.duplicateLabelError
        }
        if servers.contains(where: { $0.id == server.id && $0.id != editingServerId }) {
            return draftErrorMessage = Self.duplicateAddressError
        }

        let reachable = await store.isReachable(server)

        if !reachable {
            return draftErrorMessage = Self.serverUnreachableError
        }

        if let originalId = editingServerId, let index = servers.firstIndex(where: { $0.id == originalId }) {
            servers[index] = server
        } else {
            servers.append(server)
        }
        closeServerForm()
    }

    func continueSetup() async {
        guard canContinue else { return }

        errorMessage = nil
        loading = true
        defer { loading = false }

        do {
            try await store.save(servers)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
