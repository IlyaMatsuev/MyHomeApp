import Foundation
@testable import MyHomeApp

final class StubAuthTokenPersistence: AuthTokenPersistence, @unchecked Sendable {
    var loadResult: Result<AuthToken?, Error> = .success(nil)

    private(set) var savedTokens: [AuthToken] = []
    private(set) var clearCallCount = 0

    func load() throws -> AuthToken? {
        try loadResult.get()
    }

    func save(_ token: AuthToken) throws {
        savedTokens.append(token)
    }

    func clear() throws {
        clearCallCount += 1
    }
}
