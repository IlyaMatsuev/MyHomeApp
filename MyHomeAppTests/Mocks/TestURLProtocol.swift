import Foundation
import os

final class TestURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    // Keyed by host so suites running in parallel can't answer each other's requests; `nil` answers any other host.
    private static let handlers = OSAllocatedUnfairLock<[String?: Handler]>(initialState: [:])

    fileprivate static func setHandler(_ handler: @escaping Handler, forHost host: String?) {
        handlers.withLock { $0[host] = handler }
    }

    override static func canInit(with _: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let host = request.url?.host()
        guard let handler = Self.handlers.withLock({ $0[host] ?? $0[nil] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            if response.statusCode == 302, let location = response.value(forHTTPHeaderField: "Location") {
                var redirected = request
                redirected.url = URL(string: location)
                client?.urlProtocol(self, wasRedirectedTo: redirected, redirectResponse: response)
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension URLSession {
    /// Pass `host` from a suite that isn't serialized with the other `TestURLProtocol` users. Without it the handler
    /// answers every host no other session claimed, including redirect targets.
    static func testSession(host: String? = nil, handler: @escaping TestURLProtocol.Handler) -> URLSession {
        TestURLProtocol.setHandler(handler, forHost: host)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TestURLProtocol.self]
        return URLSession(configuration: config)
    }
}
