import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct ServerSetupViewModelHeadersTests {
    private static let server = Server(.https, "home.example.com", remote: true, label: "Cabin")
        .withHeaders(ServerHeader(name: "X-Proxy-Key", value: "s3cr3t"))

    private let service: StubServerConfigService
    private let viewModel: ServerSetupViewModel

    init() {
        service = StubServerConfigService()
        viewModel = ServerSetupViewModel(
            mode: .initialSetup,
            store: ServerConfigStore(persistence: StubServerConfigPersistence(), service: service)
        )
    }

    // MARK: - draft rows

    @Test
    func showAddServerFormAfterEditingStartsWithNoHeaders() {
        viewModel.showEditServerForm(Self.server)
        viewModel.closeServerForm()

        viewModel.showAddServerForm()

        #expect(viewModel.draftServer.headers.isEmpty)
    }

    @Test
    func addHeaderAppendsBlankRow() throws {
        viewModel.showEditServerForm(Self.server)

        viewModel.addHeader()

        #expect(viewModel.draftServer.headers.count == 2)
        #expect(viewModel.draftServer.headers.first == Self.server.headers.first)
        let added = try #require(viewModel.draftServer.headers.last)
        #expect(added.isBlank)
    }

    @Test
    func removeHeadersRemovesEveryRowAtOffsets() {
        let kept = ServerHeader(name: "X-Kept", value: "1")
        viewModel.showAddServerForm()
        viewModel.draftServer.headers = [ServerHeader(name: "X-First"), kept, ServerHeader(name: "X-Last")]

        viewModel.removeHeaders(at: [0, 2])

        #expect(viewModel.draftServer.headers == [kept])
    }

    @Test
    func closingEditFormLeavesServersUntouched() {
        viewModel.servers = [Self.server]
        viewModel.showEditServerForm(Self.server)
        viewModel.draftServer.headers[0].value = "changed"
        viewModel.addHeader()

        viewModel.closeServerForm()

        #expect(viewModel.servers == [Self.server])
    }

    // MARK: - saveDraft()

    @Test(arguments: [true, false])
    func saveDraftChecksAndStoresTrimmedHeadersWithoutBlankRows(editing: Bool) async throws {
        if editing {
            viewModel.servers = [Self.server]
            viewModel.showEditServerForm(Self.server)
        } else {
            viewModel.showAddServerForm()
            viewModel.draftServer.address = "hub.home"
        }
        let header = ServerHeader(name: " X-Tenant ", value: " my home\n")
        viewModel.draftServer.headers = [ServerHeader(), header, ServerHeader(name: " ", value: "\t")]

        await viewModel.saveDraft()

        let expected = [ServerHeader(id: header.id, name: "X-Tenant", value: "my home")]
        #expect(service.checkedServers.map(\.headers) == [expected])
        #expect(viewModel.servers.map(\.headers) == [expected])
        #expect(!viewModel.isServerFormOpen)
    }

    @Test(arguments: [
        (
            [ServerHeader(name: "X Key", value: "1")],
            "Enter a valid header name. Example: X-Proxy-Key"
        ),
        (
            [ServerHeader(name: "", value: "1")],
            "Enter a valid header name. Example: X-Proxy-Key"
        ),
        (
            [ServerHeader(name: "Host", value: "1")],
            "The header \"Host\" is set by the app and can't be changed."
        ),
        (
            [ServerHeader(name: "X-Key", value: "é")],
            "Enter a valid value for the header \"X-Key\"."
        ),
        (
            [ServerHeader(name: "X-Key", value: " ")],
            "Enter a valid value for the header \"X-Key\"."
        ),
        (
            [ServerHeader(name: "X-Key", value: "1"), ServerHeader(name: "x-key ", value: "2")],
            "You already have a header named \"x-key\"."
        )
    ])
    func saveDraftRejectsInvalidHeadersWithoutCallingService(headers: [ServerHeader], message: String) async {
        viewModel.servers = [Self.server]
        viewModel.showEditServerForm(Self.server)
        viewModel.draftServer.headers = headers

        await viewModel.saveDraft()

        #expect(viewModel.draftErrorMessage == message)
        #expect(service.checkedServers.isEmpty)
        #expect(viewModel.servers == [Self.server])
        #expect(viewModel.isServerFormOpen)
        #expect(!viewModel.loading)
    }

    @Test
    func addHeaderClearsDraftError() async {
        viewModel.showEditServerForm(Self.server)
        viewModel.draftServer.headers = [ServerHeader(name: "Host", value: "1")]
        await viewModel.saveDraft()
        #expect(viewModel.draftErrorMessage != nil)

        viewModel.addHeader()

        #expect(viewModel.draftErrorMessage == nil)
    }
}
