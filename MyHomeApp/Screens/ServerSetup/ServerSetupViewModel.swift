import Foundation
import Observation

@Observable
@MainActor
final class ServerSetupViewModel {
    private static let duplicateLabelError = "You already have a server with the same label."
    private static let duplicateAddressError = "You already have a server with the same address."
    private static let invalidHostAddressError = "Enter a valid address. Example: 192.168.1.10:8080"
    private static let serverUnreachableError = "Couldn't connect to the server."
    private static let invalidHeaderNameError = "Enter a valid header name. Example: X-Proxy-Key"
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

    func addHeader() {
        draftServer.headers.append(ServerHeader())
    }

    func removeHeaders(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where draftServer.headers.indices.contains(index) {
            draftServer.headers.remove(at: index)
        }
    }

    func saveDraft() async {
        guard canSaveDraft else {
            draftErrorMessage = Self.invalidHostAddressError
            return
        }

        errorMessage = nil
        loading = true
        defer { loading = false }

        if servers.contains(where: { $0.label == draftServer.label && $0.id != editingServerId }) {
            draftErrorMessage = Self.duplicateLabelError
            return
        }
        if servers.contains(where: { $0.id == draftServer.id && $0.id != editingServerId }) {
            draftErrorMessage = Self.duplicateAddressError
            return
        }

        var server = draftServer
        server.headers = server.headers.map(\.trimmed).filter { !$0.isBlank }
        if let message = headersError(in: server.headers) {
            draftErrorMessage = message
            return
        }

        let reachable = await store.isReachable(server)

        if !reachable {
            draftErrorMessage = Self.serverUnreachableError
            return
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

    private func headersError(in headers: [ServerHeader]) -> String? {
        var names: Set<String> = []
        for header in headers {
            if !header.hasValidName {
                return Self.invalidHeaderNameError
            }
            if header.isReserved {
                return "The header \"\(header.name)\" is set by the app and can't be changed."
            }
            if !header.hasValidValue {
                return "Enter a valid value for the header \"\(header.name)\"."
            }
            if !names.insert(header.name.lowercased()).inserted {
                return "You already have a header named \"\(header.name)\"."
            }
        }
        return nil
    }
}
