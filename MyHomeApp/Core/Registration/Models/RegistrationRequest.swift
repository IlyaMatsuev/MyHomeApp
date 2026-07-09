struct RegistrationRequest: Codable, Equatable, Hashable, Identifiable, Sendable {
    let externalId: String
    let email: String
    let requesterComment: String?

    let status: RegistrationRequestStatus
    let role: UserRole
    let blocked: Bool

    var id: String { externalId }
}
