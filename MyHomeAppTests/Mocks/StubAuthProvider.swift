import Foundation
@testable import MyHomeApp

@MainActor
final class StubAuthProvider: AuthProvider {
    var sessionToken: AuthToken?
    var refreshHandler: @MainActor () async -> Bool

    private(set) var refreshCount = 0

    init(sessionToken: AuthToken? = nil, refreshHandler: @escaping @MainActor () async -> Bool = { false }) {
        self.sessionToken = sessionToken
        self.refreshHandler = refreshHandler
    }

    func refreshToken() async -> Bool {
        refreshCount += 1
        return await refreshHandler()
    }
}
