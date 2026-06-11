import Foundation
@testable import SmartHomeAppIOS

final class StubServerConfigPersistence: ServerConfigPersistence, @unchecked Sendable {
    var loadResult: Result<[Server]?, Error> = .success(nil)
    var saveError: Error?
    var clearError: Error?

    private(set) var savedServers: [[Server]] = []
    private(set) var clearCallCount = 0

    func load() throws -> [Server]? {
        try loadResult.get()
    }

    func save(_ servers: [Server]) throws {
        if let saveError { throw saveError }
        savedServers.append(servers)
    }

    func clear() throws {
        clearCallCount += 1
        if let clearError { throw clearError }
    }
}
