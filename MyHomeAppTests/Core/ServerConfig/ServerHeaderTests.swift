import Foundation
import Testing
@testable import MyHomeApp

struct ServerHeaderTests {
    // MARK: - name

    @Test(arguments: ["X-Proxy-Key", "x_key.1", "0", "!#$%&'*+-.^_`|~"])
    func tokenNameIsValid(name: String) {
        #expect(ServerHeader(name: name).hasValidName)
    }

    @Test(arguments: ["", "X Key", "X-Key:", "X-Key\n", "X-Key\r\n", "X-Clé", "X-Ключ", "X/Key", "(X)"])
    func nonTokenNameIsInvalid(name: String) {
        #expect(!ServerHeader(name: name).hasValidName)
    }

    @Test(arguments: [
        "accept", "Authorization", "CONNECTION", "Content-Length", "content-Type", "Host",
        "Proxy-Authenticate", "Proxy-Authorization", "Transfer-Encoding", "WWW-Authenticate"
    ])
    func ownedNameIsReservedRegardlessOfCase(name: String) {
        #expect(ServerHeader(name: name).isReserved)
    }

    @Test(arguments: ["X-Proxy-Key", "X-Authorization", "Accept-Language"])
    func otherNameIsNotReserved(name: String) {
        #expect(!ServerHeader(name: name).isReserved)
    }

    // MARK: - value

    @Test(arguments: ["s3cr3t", "Basic abc def", "!~"])
    func printableASCIIValueIsValid(value: String) {
        #expect(ServerHeader(value: value).hasValidValue)
    }

    @Test(arguments: ["", "a\nb", "a\r\nb", "a\tb", "a\u{7F}", "\u{201C}quoted\u{201D}", "é"])
    func emptyOrNonPrintableASCIIValueIsInvalid(value: String) {
        #expect(!ServerHeader(value: value).hasValidValue)
    }

    // MARK: - trimmed

    @Test
    func trimmedStripsOuterWhitespaceOnlyAndKeepsId() {
        let header = ServerHeader(name: " X-Key\n", value: "\t a b ")

        #expect(header.trimmed == ServerHeader(id: header.id, name: "X-Key", value: "a b"))
    }

    // MARK: - isBlank

    @Test(arguments: [
        ("", "", true),
        (" ", "\n", true),
        ("X-Key", "", false),
        ("", "s3cr3t", false)
    ])
    func isBlankOnlyWhenBothFieldsAreBlank(name: String, value: String, expected: Bool) {
        #expect(ServerHeader(name: name, value: value).isBlank == expected)
    }
}
