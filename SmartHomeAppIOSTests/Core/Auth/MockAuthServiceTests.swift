import Foundation
import Testing
@testable import SmartHomeAppIOS

struct MockAuthServiceTests {
    private let service = MockAuthService(operationDelay: .zero)

    private let validEmail = "test@example.com"
    private let validPassword = "password"

    // MARK: - login()

    @Test
    func loginWithValidCredentialsReturnsToken() async throws {
        let token = try await service.login(email: validEmail, password: validPassword)

        #expect(!token.accessToken.isEmpty)
    }

    @Test
    func loginWithInvalidEmailThrowsInvalidLoginCredentials() async {
        await #expect(throws: AuthError.invalidLoginCredentials) {
            _ = try await service.login(email: "wrong@example.com", password: validPassword)
        }
    }

    @Test
    func loginWithInvalidPasswordThrowsInvalidLoginCredentials() async {
        await #expect(throws: AuthError.invalidLoginCredentials) {
            _ = try await service.login(email: validEmail, password: "nope")
        }
    }
}
