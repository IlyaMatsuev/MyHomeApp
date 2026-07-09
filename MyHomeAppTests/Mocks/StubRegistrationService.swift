import Foundation
@testable import MyHomeApp

final class StubRegistrationService: RegistrationService, @unchecked Sendable {
    var requestAccessResult: Result<RegistrationRequest, Error> = .success(
        .fixture(externalId: "stub-id", email: "stub@example.com", role: .guest)
    )
    var refreshRequestResult: Result<RegistrationRequest, Error> = .success(
        .fixture(externalId: "stub-id", email: "stub@example.com", role: .guest)
    )
    var cancelRequestResult: Result<Void, Error> = .success(())

    private(set) var requestAccessCallCount = 0
    private(set) var requestedEmails: [String] = []
    private(set) var requestedComments: [String?] = []
    private(set) var refreshRequestCallCount = 0
    private(set) var refreshedRequestIds: [String] = []
    private(set) var cancelRequestCallCount = 0
    private(set) var cancelledRequestIds: [String] = []

    func requestAccess(email: String, comment: String?) async throws -> RegistrationRequest {
        requestAccessCallCount += 1
        requestedEmails.append(email)
        requestedComments.append(comment)
        return try requestAccessResult.get()
    }

    func refreshRequest(requestId: String) async throws -> RegistrationRequest {
        refreshRequestCallCount += 1
        refreshedRequestIds.append(requestId)
        return try refreshRequestResult.get()
    }

    func cancelRequest(requestId: String) async throws {
        cancelRequestCallCount += 1
        cancelledRequestIds.append(requestId)
        try cancelRequestResult.get()
    }
}
