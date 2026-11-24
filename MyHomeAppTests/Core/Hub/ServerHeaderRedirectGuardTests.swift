import Foundation
import Testing
@testable import MyHomeApp

struct ServerHeaderRedirectGuardTests {
    private static let originalHeaders = ["X-Proxy-Key": "s3cr3t", "X-Tenant": "home", "Accept": "application/json"]

    private let redirectGuard = ServerHeaderRedirectGuard(
        server: Server(.https, "Hub.example.com:8443").withHeaders(
            ServerHeader(name: "X-Proxy-Key", value: "s3cr3t"),
            ServerHeader(name: "X-Tenant", value: "home")
        )
    )

    @Test(arguments: ["https://Hub.example.com:8443/new", "https://hub.EXAMPLE.com:8443/new"])
    func sameHostKeepsHeadersRegardlessOfCase(location: String) async throws {
        let request = try #require(try await redirect(to: location))

        #expect(request.url?.absoluteString == location)
        #expect(request.allHTTPHeaderFields == Self.originalHeaders)
    }

    @Test(arguments: [
        "https://evil.com/new",
        "https://sub.hub.example.com:8443/new",
        "https://hub.example.com.evil.com/new"
    ])
    func differentHostStripsOnlyCustomHeaders(location: String) async throws {
        let request = try #require(try await redirect(to: location))

        #expect(request.url?.absoluteString == location)
        #expect(request.allHTTPHeaderFields == ["Accept": "application/json"])
    }

    private func redirect(to location: String) async throws -> URLRequest? {
        let origin = try #require(URL(string: "https://hub.example.com:8443"))
        let response = try #require(HTTPURLResponse(url: origin, statusCode: 302, httpVersion: nil, headerFields: nil))
        var newRequest = URLRequest(url: try #require(URL(string: location)))
        newRequest.allHTTPHeaderFields = Self.originalHeaders

        return await withCheckedContinuation { [newRequest] continuation in
            redirectGuard.urlSession(
                .shared,
                task: URLSession.shared.dataTask(with: origin),
                willPerformHTTPRedirection: response,
                newRequest: newRequest
            ) { continuation.resume(returning: $0) }
        }
    }
}
