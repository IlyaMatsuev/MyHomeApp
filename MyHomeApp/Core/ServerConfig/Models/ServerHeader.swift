import Foundation

/// A custom HTTP header sent with every request to a server — e.g. the token a reverse proxy checks
/// before it lets a request from outside the home network through.
struct ServerHeader: Codable, Equatable, Hashable, Sendable, Identifiable {
    /// RFC 9110 `tchar`: the only characters a header name may contain.
    private static let nameCharacters = CharacterSet(
        charactersIn: "!#$%&'*+-.^_`|~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    )

    /// Lowercased names the app sends itself, or that URLSession reserves and silently drops.
    private static let reservedNames: Set<String> = [
        "accept",
        "authorization",
        "connection",
        "content-length",
        "content-type",
        "host",
        "proxy-authenticate",
        "proxy-authorization",
        "www-authenticate"
    ]

    let id: UUID
    var name: String
    var value: String

    /// A row the user added but never filled in. It's dropped on save rather than blocking it.
    var isBlank: Bool {
        name.isBlank && value.isBlank
    }

    /// The name as HTTP compares it: header names are case-insensitive.
    var normalizedName: String {
        name.trimmed.lowercased()
    }

    var hasValidName: Bool {
        let trimmedName = name.trimmed
        return !trimmedName.isEmpty && trimmedName.unicodeScalars.allSatisfy { Self.nameCharacters.contains($0) }
    }

    var hasReservedName: Bool {
        Self.reservedNames.contains(normalizedName)
    }

    /// Non-empty printable ASCII and tabs. RFC 9110 also tolerates obsolete non-ASCII bytes, but URLSession has
    /// no reliable encoding for them, and CR/LF would let a value smuggle in extra headers.
    var hasValidValue: Bool {
        let trimmedValue = value.trimmed
        return !trimmedValue.isEmpty
            && trimmedValue.unicodeScalars.allSatisfy { $0 == "\t" || (0x20...0x7E).contains($0.value) }
    }

    var isValid: Bool {
        isBlank || (hasValidName && !hasReservedName && hasValidValue)
    }

    /// Surrounding whitespace removed — a pasted token often brings a trailing newline along.
    var trimmed: ServerHeader {
        ServerHeader(id: id, name: name.trimmed, value: value.trimmed)
    }

    init(id: UUID = UUID(), name: String = "", value: String = "") {
        self.id = id
        self.name = name
        self.value = value
    }
}
