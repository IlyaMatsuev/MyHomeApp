import Foundation

struct ServerHeader: Codable, Equatable, Identifiable, Sendable {
    /// Names `HubAPIClient` or URLSession owns. Lowercased: header names are case-insensitive.
    private static let reservedNames: Set<String> = [
        "accept", "authorization", "connection", "content-length", "content-type", "host",
        "proxy-authenticate", "proxy-authorization", "transfer-encoding", "www-authenticate"
    ]
    /// RFC 9110 `token`.
    private static let namePattern = /[A-Za-z0-9!#$%&'*+.^_`|~\-]+/

    var id = UUID()
    var name = ""
    var value = ""

    var isBlank: Bool {
        name.isBlank && value.isBlank
    }

    var trimmed: Self {
        Self(id: id, name: name.trimmed, value: value.trimmed)
    }

    var hasValidName: Bool {
        (try? Self.namePattern.wholeMatch(in: name)) != nil
    }

    var isReserved: Bool {
        Self.reservedNames.contains(name.lowercased())
    }

    /// Printable ASCII only: URLSession silently mangles or drops anything else.
    var hasValidValue: Bool {
        !value.isEmpty && value.utf8.allSatisfy { (0x20...0x7E).contains($0) }
    }
}
