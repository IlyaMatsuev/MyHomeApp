import Foundation

struct MockRegistrationService: RegistrationService {
    private let operationDelay: Duration
    private let resolvedStatus: RegistrationStatus

    init(operationDelay: Duration = .seconds(1), status: RegistrationStatus = .pending) {
        self.operationDelay = operationDelay
        self.resolvedStatus = status
    }

    func requestAccess(email: String, comment _: String?) async throws -> RegistrationRequest {
        try await Task.sleep(for: operationDelay)
        return RegistrationRequest(
            externalId: "mock-registration-id",
            email: email,
            status: .pending
        )
    }

    func checkStatus(requestId: String) async throws -> RegistrationStatus {
        try await Task.sleep(for: operationDelay)
        return resolvedStatus
    }

    func cancelRequest(requestId _: String) async throws {
        try await Task.sleep(for: operationDelay)
    }
}
