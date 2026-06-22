struct RegistrationRequest: Codable, Equatable, Hashable, Identifiable, Sendable {
    let externalId: String
    let email: String
    let status: RegistrationStatus

    var id: String { externalId }
}

extension RegistrationRequest {
    func withStatus(_ status: RegistrationStatus) -> RegistrationRequest {
        RegistrationRequest(externalId: externalId, email: email, status: status)
    }
}
