protocol RegistrationService: Sendable {
    func requestAccess(email: String) async throws -> RegistrationRequest
    func checkStatus(requestId: String) async throws -> RegistrationStatus
}
