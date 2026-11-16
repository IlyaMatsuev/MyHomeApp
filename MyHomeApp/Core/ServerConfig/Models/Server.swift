import Foundation

struct Server: Codable, Equatable, Sendable, Identifiable {
    var label: String
    var scheme: AddressScheme
    var address: String
    var remote: Bool
    var headers: [ServerHeader]

    var id: String {
        address
    }

    var fullURL: String {
        "\(scheme)://\(address)"
    }

    var baseURL: URL? {
        guard !address.isEmpty else { return nil }
        guard let components = URLComponents(string: fullURL), components.host?.isEmpty == false else {
            return nil
        }
        return components.url
    }

    var valid: Bool {
        !label.isEmpty && baseURL != nil && hasValidHeaders
    }

    var hasValidHeaders: Bool {
        headers.allSatisfy(\.isValid) && duplicateHeaderNames.isEmpty
    }

    /// Normalized names of the headers set more than once: only one of them would be sent.
    var duplicateHeaderNames: Set<String> {
        var seen: Set<String> = []
        var duplicates: Set<String> = []
        for header in headers where !header.isBlank {
            if !seen.insert(header.normalizedName).inserted {
                duplicates.insert(header.normalizedName)
            }
        }
        return duplicates
    }

    var iconSystemName: String {
        remote ? "globe" : "house"
    }

    private enum CodingKeys: String, CodingKey {
        case label
        case scheme
        case address
        case remote
        case headers
    }

    init(
        _ scheme: AddressScheme,
        _ address: String,
        remote: Bool = false,
        label: String = "",
        headers: [ServerHeader] = []
    ) {
        self.scheme = scheme
        self.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.remote = remote
        self.label = label.isEmpty ? address : label
        self.headers = headers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        scheme = try container.decode(AddressScheme.self, forKey: .scheme)
        address = try container.decode(String.self, forKey: .address)
        remote = try container.decode(Bool.self, forKey: .remote)
        // Servers saved before custom headers existed have no `headers` key.
        headers = try container.decodeIfPresent([ServerHeader].self, forKey: .headers) ?? []
    }
}
