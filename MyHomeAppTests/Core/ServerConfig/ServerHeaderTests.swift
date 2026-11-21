import Foundation
import Testing
@testable import MyHomeApp

struct ServerHeaderTests {
    // MARK: - isBlank

    @Test
    func newHeaderIsBlank() {
        #expect(ServerHeader().isBlank)
    }

    @Test
    func whitespaceOnlyHeaderIsBlank() {
        #expect(ServerHeader(name: "  ", value: "\n").isBlank)
    }

    @Test
    func headerWithOnlyValueIsNotBlank() {
        #expect(!ServerHeader(name: "", value: "token").isBlank)
    }

    // MARK: - hasValidName

    @Test(arguments: ["X-Proxy-Authorization", "x-api-key", "X_Token", "Custom.Header~1"])
    func tokenCharacterNamesAreValid(name: String) {
        #expect(ServerHeader(name: name, value: "token").hasValidName)
    }

    @Test(arguments: ["", "X Proxy", "X-Proxy:", "Header(1)", "Ключ", "X\"Quoted"])
    func namesOutsideTokenCharactersAreInvalid(name: String) {
        #expect(!ServerHeader(name: name, value: "token").hasValidName)
    }

    @Test
    func nameIsValidatedWithoutSurroundingWhitespace() {
        #expect(ServerHeader(name: " X-Api-Key ", value: "token").hasValidName)
    }

    // MARK: - hasReservedName

    @Test(arguments: ["Authorization", "proxy-authorization", " HOST ", "Content-Type", "Accept"])
    func namesTheAppOrURLSessionSetAreReserved(name: String) {
        #expect(ServerHeader(name: name, value: "token").hasReservedName)
    }

    @Test
    func proxyTokenHeaderIsNotReserved() {
        #expect(!ServerHeader(name: "X-Proxy-Authorization", value: "token").hasReservedName)
    }

    // MARK: - hasValidValue

    @Test
    func printableASCIIValueIsValid() {
        #expect(ServerHeader(name: "X-Api-Key", value: "app_0f3a Bearer=+/~").hasValidValue)
    }

    @Test(arguments: ["", "  \n"])
    func emptyValueIsInvalid(value: String) {
        #expect(!ServerHeader(name: "X-Api-Key", value: value).hasValidValue)
    }

    @Test
    func trailingNewlineFromAPasteIsIgnored() {
        #expect(ServerHeader(name: "X-Api-Key", value: "token\n").hasValidValue)
    }

    @Test(arguments: ["tok\nen", "tok\r\nX-Injected: 1", "tökén", "tok\u{7F}en"])
    func valuesWithControlOrNonASCIICharactersAreInvalid(value: String) {
        #expect(!ServerHeader(name: "X-Api-Key", value: value).hasValidValue)
    }

    // MARK: - isValid

    @Test
    func blankHeaderIsValidSoItDoesNotBlockSaving() {
        #expect(ServerHeader().isValid)
    }

    @Test
    func headerWithValueButNoNameIsInvalid() {
        #expect(!ServerHeader(name: "", value: "token").isValid)
    }

    @Test
    func headerWithNameButNoValueIsInvalid() {
        #expect(!ServerHeader(name: "X-Api-Key", value: "").isValid)
    }

    @Test
    func headerWithReservedNameIsInvalid() {
        #expect(!ServerHeader(name: "Proxy-Authorization", value: "token").isValid)
    }

    @Test
    func headerWithValidNameAndValueIsValid() {
        #expect(ServerHeader(name: "X-Proxy-Authorization", value: "token").isValid)
    }

    // MARK: - trimmed

    @Test
    func trimmedStripsWhitespaceAndKeepsIdentity() {
        let header = ServerHeader(name: " X-Api-Key ", value: " token\n")

        let trimmed = header.trimmed

        #expect(trimmed.id == header.id)
        #expect(trimmed.name == "X-Api-Key")
        #expect(trimmed.value == "token")
    }
}
