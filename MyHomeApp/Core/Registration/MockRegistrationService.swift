import Foundation

struct MockRegistrationService: RegistrationService {
    private let operationDelay: Duration
    private let resolvedStatus: RegistrationRequestStatus

    init(operationDelay: Duration = .seconds(1), status: RegistrationRequestStatus = .pending) {
        self.operationDelay = operationDelay
        self.resolvedStatus = status
    }

    func requestAccess(email: String, comment: String?) async throws -> RegistrationRequest {
        try await Task.sleep(for: operationDelay)
        return RegistrationRequest(
            externalId: "mock-registration-id",
            email: email,
            requesterComment: comment,
            status: .pending,
            role: .resident,
            blocked: false
        )
    }

    func refreshRequest(requestId: String) async throws -> RegistrationRequest {
        try await Task.sleep(for: operationDelay)
        return RegistrationRequest(
            externalId: requestId,
            email: "mock@home.dev",
            requesterComment: "I would love to join this Home.",
            status: resolvedStatus,
            role: .resident,
            blocked: resolvedStatus == .rejected
        )
    }

    func cancelRequest(requestId _: String) async throws {
        try await Task.sleep(for: operationDelay)
    }
}
