import Foundation

struct MediaSettings: Codable, Equatable, Sendable {
    static let serverLabel = "Media Manager"
    static let disabled = MediaSettings(enabled: false, server: Server(.http, "", label: serverLabel))

    var enabled: Bool
    /// Always a local address — the Media Manager cannot be reached remotely yet.
    var server: Server

    /// Whether the configured address can be turned into a request URL.
    var valid: Bool {
        server.baseURL != nil
    }

    /// Whether the Media Manager should be reachable: enabled *and* pointing at a usable address.
    var active: Bool {
        enabled && valid
    }
}
