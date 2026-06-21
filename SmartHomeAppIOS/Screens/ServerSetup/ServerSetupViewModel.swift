import Foundation
import Observation

@Observable
@MainActor
final class ServerSetupViewModel {
    private static let duplicateLabelError = "You already have a server with the same label."
    private static let duplicateAddressError = "You already have a server with the same address."
    private static let invalidHostAddressError = "Enter a valid address. Example: 192.168.1.10:8080"
    private static let serverUnreachableError = "Couldn't connect to the server."
    private static let defaultLabel = "Home"
    private static let serverTemplate = Server(.https, "", remote: false, label: defaultLabel)

    private let store: ServerConfigStore
    private let service: ServerConfigService

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

    init(mode: ServerSetupMode, store: ServerConfigStore, service: ServerConfigService) {
        self.mode = mode
        self.store = store
        self.service = service
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

    func saveDraft() async {
        guard canSaveDraft else {
            return draftErrorMessage = Self.invalidHostAddressError
        }

        errorMessage = nil
        loading = true
        defer { loading = false }

        if servers.contains(where: { $0.label == draftServer.label && $0.id != editingServerId }) {
            return draftErrorMessage = Self.duplicateLabelError
        }
        if servers.contains(where: { $0.id == draftServer.id && $0.id != editingServerId }) {
            return draftErrorMessage = Self.duplicateAddressError
        }

        let reachable = await service.isReachable(server: draftServer)

        if !reachable {
            return draftErrorMessage = Self.serverUnreachableError
        }

        if let originalId = editingServerId, let index = servers.firstIndex(where: { $0.id == originalId }) {
            servers[index] = draftServer
        } else {
            servers.append(draftServer)
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
