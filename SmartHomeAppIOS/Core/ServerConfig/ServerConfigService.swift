protocol ServerConfigService: Sendable {
    func isReachable(server: Server) async -> Bool
}
