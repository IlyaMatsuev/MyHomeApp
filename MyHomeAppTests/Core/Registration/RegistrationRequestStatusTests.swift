import Foundation
import Testing
@testable import MyHomeApp

struct RegistrationRequestStatusTests {
    @Test
    func decodesFromServerRawValues() throws {
        #expect(try decode("pending") == .pending)
        #expect(try decode("approved") == .approved)
        #expect(try decode("rejected") == .rejected)
        #expect(try decode("cancelled") == .cancelled)
    }

    @Test
    func rejectsUnknownRawValue() {
        #expect(throws: DecodingError.self) {
            _ = try decode("banana")
        }
    }

    private func decode(_ rawValue: String) throws -> RegistrationRequestStatus {
        try JSONDecoder().decode(RegistrationRequestStatus.self, from: Data("\"\(rawValue)\"".utf8))
    }
}
