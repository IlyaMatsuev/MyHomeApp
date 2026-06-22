import Foundation
@testable import MyHomeApp

final class StubRegistrationService: RegistrationService, @unchecked Sendable {
    var requestAccessResult: Result<RegistrationRequest, Error> = .success(
        RegistrationRequest(externalId: "stub-id", email: "stub@example.com", status: .pending)
    )
    var checkStatusResult: Result<RegistrationStatus, Error> = .success(.pending)

    private(set) var requestAccessCallCount = 0
    private(set) var requestedEmails: [String] = []
    private(set) var checkStatusCallCount = 0
    private(set) var checkedRequestIds: [String] = []

    func requestAccess(email: String) async throws -> RegistrationRequest {
        requestAccessCallCount += 1
        requestedEmails.append(email)
        return try requestAccessResult.get()
    }

    func checkStatus(requestId: String) async throws -> RegistrationStatus {
        checkStatusCallCount += 1
        checkedRequestIds.append(requestId)
        return try checkStatusResult.get()
    }
}
