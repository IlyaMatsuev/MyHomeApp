import Foundation

struct MockServerConfigService: ServerConfigService {
    private static let reachableHost = "hub.home"

    private let operationDelay: Duration

    init(operationDelay: Duration = .seconds(1)) {
        self.operationDelay = operationDelay
    }

    func isReachable(server: Server) async -> Bool {
        try? await Task.sleep(for: operationDelay)
        return !server.remote && server.baseURL?.host == Self.reachableHost
    }
}
