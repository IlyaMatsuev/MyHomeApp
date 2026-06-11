import Foundation
@testable import SmartHomeAppIOS

final class StubServerConfigService: ServerConfigService, @unchecked Sendable {
    var isReachableResult: Bool = true

    private(set) var checkedServers: [Server] = []

    func isReachable(server: Server) async -> Bool {
        checkedServers.append(server)
        return isReachableResult
    }
}
