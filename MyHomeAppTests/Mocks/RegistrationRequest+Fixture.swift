@testable import MyHomeApp

extension RegistrationRequest {
    static func fixture(
        externalId: String = "r-1",
        email: String = "a@b.dev",
        requesterComment: String? = nil,
        status: RegistrationRequestStatus = .pending,
        role: UserRole = .resident,
        blocked: Bool = false
    ) -> RegistrationRequest {
        RegistrationRequest(
            externalId: externalId,
            email: email,
            requesterComment: requesterComment,
            status: status,
            role: role,
            blocked: blocked
        )
    }
}
