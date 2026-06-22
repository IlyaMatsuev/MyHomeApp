import Foundation
@testable import MyHomeApp

final class StubRegistrationPersistence: RegistrationPersistence, @unchecked Sendable {
    var loadResult: Result<RegistrationRequest?, Error> = .success(nil)

    private(set) var savedRequests: [RegistrationRequest] = []
    private(set) var clearCallCount = 0

    func load() throws -> RegistrationRequest? {
        try loadResult.get()
    }

    func save(_ request: RegistrationRequest) throws {
        savedRequests.append(request)
    }

    func clear() throws {
        clearCallCount += 1
    }
}
