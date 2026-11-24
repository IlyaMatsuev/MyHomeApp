import Foundation
import Testing
@testable import MyHomeApp

struct KeychainItemTests {
    // Runs against the real Keychain: every other suite stubs the storage, so nothing else executes these queries.
    @Test
    func writeReadAndDeleteRoundTrip() throws {
        let item = KeychainItem(account: "test-\(UUID().uuidString)")
        defer { try? item.delete() }

        #expect(try item.read() == nil)

        try item.write(Data("a".utf8))
        try item.write(Data("b".utf8))
        #expect(try item.read() == Data("b".utf8))

        try item.delete()
        try item.delete()
        #expect(try item.read() == nil)
    }
}
