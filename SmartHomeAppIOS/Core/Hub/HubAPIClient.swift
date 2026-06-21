import Foundation

protocol HubAPIClient: Sendable {
    func send<T: Decodable & Sendable>(_ request: HubRequest) async throws -> T
    func send(_ request: HubRequest) async throws

    func send<T: Decodable & Sendable>(_ request: HubRequest, to server: Server) async throws -> T
    func send(_ request: HubRequest, to server: Server) async throws
}
