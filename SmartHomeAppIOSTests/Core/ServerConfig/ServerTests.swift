import Foundation
import Testing
@testable import SmartHomeAppIOS

struct ServerTests {
    // MARK: - baseURL

    @Test
    func baseURLWithHTTPSchemeAndPort() throws {
        let server = Server(.http, "192.168.1.10:8080", remote: false)
        let url = try #require(server.baseURL)
        #expect(url.absoluteString == "http://192.168.1.10:8080")
    }

    @Test
    func baseURLWithHTTPSAndDomain() throws {
        let server = Server(.https, "home.example.com", remote: true)
        let url = try #require(server.baseURL)
        #expect(url.absoluteString == "https://home.example.com")
    }

    @Test
    func baseURLTrimsAddressWhitespace() throws {
        let server = Server(.http, "  hub.local  ", remote: false)
        let url = try #require(server.baseURL)
        #expect(url.host == "hub.local")
    }

    @Test
    func baseURLIsNilForEmptyAddress() {
        let server = Server(.http, "", remote: false)
        #expect(server.baseURL == nil)
    }

    // MARK: - Codable

    @Test
    func codableRoundTripPreservesArrayOfServers() throws {
        let original = [
            Server(.http, "192.168.1.10:8080", remote: false),
            Server(.https, "home.example.com", remote: true)
        ]
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([Server].self, from: encoded)
        #expect(decoded == original)
    }
}
