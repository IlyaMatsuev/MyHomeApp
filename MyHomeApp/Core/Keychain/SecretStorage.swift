import Foundation

protocol SecretStorage: Sendable {
    func read() throws -> Data?
    func write(_ data: Data) throws
    func delete() throws
}
