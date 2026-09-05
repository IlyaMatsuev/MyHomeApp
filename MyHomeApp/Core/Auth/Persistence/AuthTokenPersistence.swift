import Foundation

protocol AuthTokenPersistence: Sendable {
    func load() throws -> AuthToken?
    func save(_ token: AuthToken) throws
    func clear() throws
}
