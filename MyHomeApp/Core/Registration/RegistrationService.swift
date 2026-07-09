protocol RegistrationService: Sendable {
    func requestAccess(email: String, comment: String?) async throws -> RegistrationRequest
    func refreshRequest(requestId: String) async throws -> RegistrationRequest
    func cancelRequest(requestId: String) async throws
}
