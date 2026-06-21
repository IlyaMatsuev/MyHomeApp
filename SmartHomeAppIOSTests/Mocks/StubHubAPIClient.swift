import Foundation
@testable import SmartHomeAppIOS

final class StubHubAPIClient: HubAPIClient, @unchecked Sendable {
    enum Response: Sendable {
        case data(Data)
        case error(Error)
    }

    var response: Response = .data(Data())
    private(set) var sentRequests: [HubRequest] = []
    private(set) var sentTargets: [Server?] = []

    func send<T: Decodable & Sendable>(_ request: HubRequest) async throws -> T {
        try record(request, target: nil)
    }

    func send(_ request: HubRequest) async throws {
        try recordVoid(request, target: nil)
    }

    func send<T: Decodable & Sendable>(_ request: HubRequest, to server: Server) async throws -> T {
        try record(request, target: server)
    }

    func send(_ request: HubRequest, to server: Server) async throws {
        try recordVoid(request, target: server)
    }

    private func record<T: Decodable & Sendable>(_ request: HubRequest, target: Server?) throws -> T {
        sentRequests.append(request)
        sentTargets.append(target)
        switch response {
        case .data(let data):
            return try JSONDecoder().decode(T.self, from: data)
        case .error(let error):
            throw error
        }
    }

    private func recordVoid(_ request: HubRequest, target: Server?) throws {
        sentRequests.append(request)
        sentTargets.append(target)
        if case .error(let error) = response {
            throw error
        }
    }
}
