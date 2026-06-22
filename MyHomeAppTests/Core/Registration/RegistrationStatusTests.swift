import Foundation
import Testing
@testable import MyHomeApp

struct RegistrationStatusTests {
    @Test
    func decodesFromServerRawValues() throws {
        #expect(try decode("pending") == .pending)
        #expect(try decode("approved") == .approved)
        #expect(try decode("rejected") == .rejected)
    }

    @Test
    func rejectsUnknownRawValue() {
        #expect(throws: DecodingError.self) {
            _ = try decode("banana")
        }
    }

    private func decode(_ rawValue: String) throws -> RegistrationStatus {
        try JSONDecoder().decode(RegistrationStatus.self, from: Data("\"\(rawValue)\"".utf8))
    }
}
