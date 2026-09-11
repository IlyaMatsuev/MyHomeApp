import Foundation

@MainActor
protocol AuthProvider {
    var sessionToken: AuthToken? { get }
    func refreshToken() async -> Bool
}
