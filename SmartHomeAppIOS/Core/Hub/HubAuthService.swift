import Foundation

struct HubAuthService: AuthService {
    private struct LoginRequest: Encodable {
        let email: String
        let password: String
    }

    private struct LoginResponse: Decodable {
        let externalId: String
        let accessToken: String
        let refreshToken: String
    }

    private let client: HubAPIClient

    init(client: HubAPIClient) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> AuthToken {
        do {
            let body = LoginRequest(email: email, password: password)
            let request = try HubRequest.put("/auth/login", body, protected: false)
            let response: LoginResponse = try await client.send(request)
            return AuthToken(
                externalId: response.externalId,
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        } catch HubAPIError.unauthorized {
            throw AuthError.invalidLoginCredentials
        } catch {
            throw AuthError.unexpected
        }
    }
}
