import Foundation
@testable import MyHomeApp

final class StubSecretStorage: SecretStorage, @unchecked Sendable {
    var data: Data?
    var readError: Error?
    var writeError: Error?
    var deleteError: Error?

    func read() throws -> Data? {
        if let readError { throw readError }
        return data
    }

    func write(_ data: Data) throws {
        if let writeError { throw writeError }
        self.data = data
    }

    func delete() throws {
        if let deleteError { throw deleteError }
        data = nil
    }
}
