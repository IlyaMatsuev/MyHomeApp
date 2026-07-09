import Foundation
import Testing
@testable import MyHomeApp

struct HubServerConfigServiceTests {
    private static let server = Server(.http, "hub.local:8080", label: "Test Hub")

    private static let validInfoJSON = Data(#"""
        {"label":"My Home Hub","address":"hub.home","port":443}
        """#.utf8)

    private let client: StubMyHomeAPIClient
    private let service: HubServerConfigService

    init() {
        client = StubMyHomeAPIClient()
        service = HubServerConfigService(client: client)
    }

    // MARK: - request shape

    @Test
    func isReachableSendsGetInfoAsUnprotectedRequestToCandidateServer() async throws {
        client.response = .data(Self.validInfoJSON)

        _ = await service.isReachable(server: Self.server)

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .get)
        #expect(request.path == "/info")
        #expect(request.protected == false)
        let target = try #require(client.sentTargets.first)
        #expect(target == Self.server)
    }

    // MARK: - success

    @Test
    func isReachableReturnsTrueWhenClientReturnsValidInfoBody() async {
        client.response = .data(Self.validInfoJSON)

        #expect(await service.isReachable(server: Self.server))
    }

    // MARK: - failure paths

    @Test
    func isReachableReturnsFalseWhenClientThrowsTransport() async {
        client.response = .error(HubAPIError.transport)

        #expect(!(await service.isReachable(server: Self.server)))
    }

    @Test
    func isReachableReturnsFalseWhenClientThrowsUnauthorized() async {
        client.response = .error(HubAPIError.unauthorized)

        #expect(!(await service.isReachable(server: Self.server)))
    }

    @Test
    func isReachableReturnsFalseWhenClientThrowsUnexpectedError() async {
        client.response = .error(HubAPIError.unexpected)

        #expect(!(await service.isReachable(server: Self.server)))
    }

    @Test
    func isReachableReturnsFalseWhenClientReturnsMalformedBody() async {
        client.response = .data(Data("not-json".utf8))

        #expect(!(await service.isReachable(server: Self.server)))
    }

    @Test
    func isReachableReturnsFalseWhenClientReturnsBodyMissingRequiredFields() async {
        client.response = .data(Data(#"{"foo":"bar"}"#.utf8))

        #expect(!(await service.isReachable(server: Self.server)))
    }
}
