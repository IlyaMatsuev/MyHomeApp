import Foundation

struct HubAuthService: AuthService {
    private struct LoginRequest: Encodable {
        let email: String
        let password: String
    }

    private struct RefreshRequest: Encodable {
        let refreshToken: String
    }

    private struct RegisterRequest: Encodable {
        let email: String
        let password: String
    }

    private struct TokenResponse: Decodable {
        let externalId: String
        let accessToken: String
        let refreshToken: String
    }

    private let client: MyHomeAPIClient

    init(client: MyHomeAPIClient) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> AuthToken {
        do {
            let body = LoginRequest(email: email, password: password)
            let request = try HubRequest.put("/auth/login", body, protected: false)
            let response: TokenResponse = try await client.send(request)
            return AuthToken(
                externalId: response.externalId,
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        } catch HubAPIError.unauthorized, HubAPIError.validation {
            throw AuthError.invalidLoginCredentials
        } catch {
            throw AuthError.unexpected
        }
    }

    func loginRefresh(refreshToken: String) async throws -> AuthToken {
        do {
            let body = RefreshRequest(refreshToken: refreshToken)
            let request = try HubRequest.put("/auth/login/refresh", body, protected: false)
            let response: TokenResponse = try await client.send(request)
            return AuthToken(
                externalId: response.externalId,
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        } catch HubAPIError.unauthorized, HubAPIError.validation {
            throw AuthError.sessionExpired
        } catch {
            throw AuthError.unexpected
        }
    }

    func register(email: String, password: String) async throws {
        do {
            let body = RegisterRequest(email: email, password: password)
            let request = try HubRequest.post("/auth/register", body, protected: false)
            try await client.send(request)
        } catch HubAPIError.conflict {
            throw AuthError.emailAlreadyTaken
        } catch HubAPIError.validation(_, let message) {
            throw AuthError.validation(message)
        } catch {
            throw AuthError.unexpected
        }
    }
}
