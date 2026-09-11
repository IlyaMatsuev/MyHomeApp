import Foundation

@MainActor
final class HubAPIContext {
    private var auth: (any AuthProvider)?
    private var servers: (any ServerProvider)?

    func attach(auth: any AuthProvider, servers: any ServerProvider) {
        self.auth = auth
        self.servers = servers
    }

    var currentServer: Server? {
        servers?.selectedServer
    }

    var currentToken: AuthToken? {
        auth?.sessionToken
    }

    func refreshToken() async -> Bool {
        guard let auth else { return false }
        return await auth.refreshToken()
    }
}
