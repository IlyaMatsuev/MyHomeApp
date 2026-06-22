import Foundation
import Testing
@testable import MyHomeApp

struct HubRegistrationServiceTests {
    private let client: StubMyHomeAPIClient
    private let service: HubRegistrationService

    init() {
        client = StubMyHomeAPIClient()
        service = HubRegistrationService(client: client)
    }

    // MARK: - requestAccess()

    @Test
    func requestAccessSendsPostToRegisterRequestsAsUnprotected() async throws {
        client.response = .data(Self.encodeCreateResponse(externalId: "req-1"))

        _ = try await service.requestAccess(email: "new@home.dev")

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .post)
        #expect(request.uri == "/auth/register/requests")
        #expect(request.protected == false)
    }

    @Test
    func requestAccessSendsEmailInRequestBody() async throws {
        client.response = .data(Self.encodeCreateResponse(externalId: "req-1"))

        _ = try await service.requestAccess(email: "new@home.dev")

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode(CreateRequestPayload.self, from: body)
        #expect(decoded == CreateRequestPayload(email: "new@home.dev"))
    }

    @Test
    func requestAccessReturnsPendingRequestWithExternalIdAndEmail() async throws {
        client.response = .data(Self.encodeCreateResponse(externalId: "req-42"))

        let result = try await service.requestAccess(email: "new@home.dev")

        #expect(result == RegistrationRequest(externalId: "req-42", email: "new@home.dev", status: .pending))
    }

    @Test
    func requestAccessMapsConflictToAlreadyRequested() async {
        client.response = .error(HubAPIError.http(status: 409, body: nil))

        await #expect(throws: RegistrationError.alreadyRequested) {
            _ = try await service.requestAccess(email: "dup@home.dev")
        }
    }

    @Test
    func requestAccessMapsOtherHubErrorsToUnexpected() async {
        client.response = .error(HubAPIError.transport)

        await #expect(throws: RegistrationError.unexpected) {
            _ = try await service.requestAccess(email: "x@home.dev")
        }
    }

    @Test
    func requestAccessMapsMalformedResponseToUnexpected() async {
        client.response = .data(Data("not-json".utf8))

        await #expect(throws: RegistrationError.unexpected) {
            _ = try await service.requestAccess(email: "x@home.dev")
        }
    }

    // MARK: - checkStatus()

    @Test
    func checkStatusSendsGetToRegisterRequestByIdAsUnprotected() async throws {
        client.response = .data(Self.encodeStatusResponse(.pending))

        _ = try await service.checkStatus(requestId: "req-7")

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .get)
        #expect(request.uri == "/auth/register/requests/req-7")
        #expect(request.protected == false)
        #expect(request.body == nil)
    }

    @Test
    func checkStatusReturnsStatusFromResponse() async throws {
        client.response = .data(Self.encodeStatusResponse(.approved))

        let status = try await service.checkStatus(requestId: "req-7")

        #expect(status == .approved)
    }

    @Test
    func checkStatusMapsNotFoundToRequestNotFound() async {
        client.response = .error(HubAPIError.http(status: 404, body: nil))

        await #expect(throws: RegistrationError.requestNotFound) {
            _ = try await service.checkStatus(requestId: "missing")
        }
    }

    @Test
    func checkStatusMapsOtherHubErrorsToUnexpected() async {
        client.response = .error(HubAPIError.transport)

        await #expect(throws: RegistrationError.unexpected) {
            _ = try await service.checkStatus(requestId: "req-7")
        }
    }

    // MARK: - helpers

    private struct CreateRequestPayload: Codable, Equatable {
        let email: String
    }

    private struct CreateResponsePayload: Encodable {
        let externalId: String
    }

    private struct StatusResponsePayload: Encodable {
        let status: String
    }

    private static func encodeCreateResponse(externalId: String) -> Data {
        // swiftlint:disable:next force_try
        try! JSONEncoder().encode(CreateResponsePayload(externalId: externalId))
    }

    private static func encodeStatusResponse(_ status: RegistrationStatus) -> Data {
        // swiftlint:disable:next force_try
        try! JSONEncoder().encode(StatusResponsePayload(status: status.rawValue))
    }
}
