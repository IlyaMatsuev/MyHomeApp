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
        client.response = .data(Self.encodeRequestResponse())

        _ = try await service.requestAccess(email: "new@home.dev", comment: nil)

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .post)
        #expect(request.path == "/auth/register/requests")
        #expect(request.protected == false)
    }

    @Test
    func requestAccessSendsEmailWithoutCommentInRequestBody() async throws {
        client.response = .data(Self.encodeRequestResponse())

        _ = try await service.requestAccess(email: "new@home.dev", comment: nil)

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode(CreateRequestPayload.self, from: body)
        #expect(decoded == CreateRequestPayload(email: "new@home.dev", comment: nil))
    }

    @Test
    func requestAccessSendsCommentInRequestBodyWhenProvided() async throws {
        client.response = .data(Self.encodeRequestResponse())

        _ = try await service.requestAccess(email: "new@home.dev", comment: "Please let me in")

        let request = try #require(client.sentRequests.first)
        let body = try #require(request.body)
        let decoded = try JSONDecoder().decode(CreateRequestPayload.self, from: body)
        #expect(decoded == CreateRequestPayload(email: "new@home.dev", comment: "Please let me in"))
    }

    @Test
    func requestAccessReturnsPendingRequestWithExternalIdAndEmail() async throws {
        client.response = .data(Self.encodeRequestResponse(externalId: "req-42", requesterEmail: "new@home.dev"))

        let result = try await service.requestAccess(email: "new@home.dev", comment: nil)

        #expect(result == RegistrationRequest.fixture(externalId: "req-42", email: "new@home.dev", status: .pending))
    }

    @Test
    func requestAccessMapsConflictToAlreadyRequested() async {
        client.response = .error(HubAPIError.conflict)

        await #expect(throws: RegistrationError.alreadyRequested) {
            _ = try await service.requestAccess(email: "dup@home.dev", comment: nil)
        }
    }

    @Test
    func requestAccessMapsForbiddenToBlocked() async {
        client.response = .error(HubAPIError.forbidden)

        await #expect(throws: RegistrationError.blocked) {
            _ = try await service.requestAccess(email: "blocked@home.dev", comment: nil)
        }
    }

    @Test
    func requestAccessMapsOtherHubErrorsToUnexpected() async {
        client.response = .error(HubAPIError.transport)

        await #expect(throws: RegistrationError.unexpected) {
            _ = try await service.requestAccess(email: "x@home.dev", comment: nil)
        }
    }

    @Test
    func requestAccessMapsMalformedResponseToUnexpected() async {
        client.response = .data(Data("not-json".utf8))

        await #expect(throws: RegistrationError.unexpected) {
            _ = try await service.requestAccess(email: "x@home.dev", comment: nil)
        }
    }

    // MARK: - refreshRequest()

    @Test
    func refreshRequestSendsGetToRegisterRequestByIdAsUnprotected() async throws {
        client.response = .data(Self.encodeRequestResponse())

        _ = try await service.refreshRequest(requestId: "req-7")

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .get)
        #expect(request.path == "/auth/register/requests/req-7")
        #expect(request.protected == false)
        #expect(request.body == nil)
    }

    @Test
    func refreshRequestMapsResponseFields() async throws {
        client.response = .data(Self.encodeRequestResponse(
            externalId: "req-7",
            requesterEmail: "a@b.dev",
            requesterComment: "let me in",
            status: .approved,
            role: .admin,
            blocked: false
        ))

        let result = try await service.refreshRequest(requestId: "req-7")

        #expect(result == RegistrationRequest.fixture(
            externalId: "req-7",
            email: "a@b.dev",
            requesterComment: "let me in",
            status: .approved,
            role: .admin
        ))
    }

    @Test
    func refreshRequestMapsNotFoundToRequestNotFound() async {
        client.response = .error(HubAPIError.notFound)

        await #expect(throws: RegistrationError.requestNotFound) {
            _ = try await service.refreshRequest(requestId: "missing")
        }
    }

    @Test
    func refreshRequestMapsOtherHubErrorsToUnexpected() async {
        client.response = .error(HubAPIError.transport)

        await #expect(throws: RegistrationError.unexpected) {
            _ = try await service.refreshRequest(requestId: "req-7")
        }
    }

    // MARK: - cancelRequest()

    @Test
    func cancelRequestSendsDeleteToRegisterRequestByIdAsUnprotected() async throws {
        client.response = .data(Data())

        try await service.cancelRequest(requestId: "req-7")

        #expect(client.sentRequests.count == 1)
        let request = try #require(client.sentRequests.first)
        #expect(request.method == .delete)
        #expect(request.path == "/auth/register/requests/req-7")
        #expect(request.protected == false)
        #expect(request.body == nil)
    }

    @Test
    func cancelRequestMapsNotFoundToRequestNotFound() async {
        client.response = .error(HubAPIError.notFound)

        await #expect(throws: RegistrationError.requestNotFound) {
            try await service.cancelRequest(requestId: "missing")
        }
    }

    @Test
    func cancelRequestMapsOtherHubErrorsToUnexpected() async {
        client.response = .error(HubAPIError.transport)

        await #expect(throws: RegistrationError.unexpected) {
            try await service.cancelRequest(requestId: "req-7")
        }
    }

    // MARK: - helpers

    private struct CreateRequestPayload: Codable, Equatable {
        let email: String
        let comment: String?
    }

    private struct RequestResponsePayload: Encodable {
        let externalId: String
        let requesterEmail: String
        let requesterComment: String?
        let status: String
        let role: String
        // swiftlint:disable:next inclusive_language
        let blackListed: Bool
    }

    private static func encodeRequestResponse(
        externalId: String = "req-1",
        requesterEmail: String = "new@home.dev",
        requesterComment: String? = nil,
        status: RegistrationRequestStatus = .pending,
        role: UserRole = .resident,
        blocked: Bool = false
    ) -> Data {
        let payload = RequestResponsePayload(
            externalId: externalId,
            requesterEmail: requesterEmail,
            requesterComment: requesterComment,
            status: status.rawValue,
            role: role.rawValue,
            blackListed: blocked
        )
        // swiftlint:disable:next force_try
        return try! JSONEncoder().encode(payload)
    }
}
