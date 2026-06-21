struct AuthToken: Codable, Equatable, Sendable {
    let externalId: String
    let accessToken: String
    let refreshToken: String
}
