import Foundation
import Testing
@testable import MyHomeApp

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

    // MARK: - iconSystemName

    @Test
    func iconSystemNameForLocalServerIsHouse() {
        let server = Server(.http, "hub.local:8080", remote: false)
        #expect(server.iconSystemName == "house")
    }

    @Test
    func iconSystemNameForRemoteServerIsGlobe() {
        let server = Server(.https, "home.example.com", remote: true)
        #expect(server.iconSystemName == "globe")
    }

    // MARK: - valid

    @Test
    func validWithLabelAddressAndNoHeaders() {
        #expect(Server(.https, "home.example.com", label: "Home").valid)
    }

    @Test
    func validIgnoresBlankHeaders() {
        let server = Server(.https, "home.example.com", label: "Home", headers: [ServerHeader()])
        #expect(server.valid)
    }

    @Test
    func invalidWhenAHeaderIsInvalid() {
        let server = Server(
            .https,
            "home.example.com",
            label: "Home",
            headers: [ServerHeader(name: "X Proxy", value: "token")]
        )
        #expect(!server.valid)
    }

    @Test
    func invalidWhenTwoHeadersShareNameIgnoringCase() {
        let server = Server(
            .https,
            "home.example.com",
            label: "Home",
            headers: [
                ServerHeader(name: "X-Proxy-Authorization", value: "old"),
                ServerHeader(name: "x-proxy-authorization ", value: "new")
            ]
        )
        #expect(server.duplicateHeaderNames == ["x-proxy-authorization"])
        #expect(!server.valid)
    }

    @Test
    func blankHeadersAreNotDuplicates() {
        let server = Server(.https, "home.example.com", label: "Home", headers: [ServerHeader(), ServerHeader()])
        #expect(server.duplicateHeaderNames.isEmpty)
        #expect(server.valid)
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

    @Test
    func codableRoundTripPreservesHeaders() throws {
        let original = Server(
            .https,
            "home.example.com",
            remote: true,
            headers: [ServerHeader(name: "X-Proxy-Authorization", value: "token")]
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Server.self, from: encoded)
        #expect(decoded == original)
    }

    @Test
    func decodingServerSavedBeforeHeadersExistedDefaultsToNoHeaders() throws {
        let legacy = Data(#"{"label":"Home","scheme":"https","address":"home.example.com","remote":true}"#.utf8)

        let decoded = try JSONDecoder().decode(Server.self, from: legacy)

        #expect(decoded.headers.isEmpty)
        #expect(decoded.label == "Home")
        #expect(decoded.address == "home.example.com")
        #expect(decoded.remote)
    }
}
