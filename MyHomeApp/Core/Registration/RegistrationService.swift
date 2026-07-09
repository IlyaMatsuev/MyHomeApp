protocol RegistrationService: Sendable {
    func requestAccess(email: String, comment: String?) async throws -> RegistrationRequest
    func checkStatus(requestId: String) async throws -> RegistrationStatus
    func cancelRequest(requestId: String) async throws
}
