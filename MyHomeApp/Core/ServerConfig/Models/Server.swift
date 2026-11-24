import Foundation

struct Server: Codable, Equatable, Sendable, Identifiable {
    var label: String
    var scheme: AddressScheme
    var address: String
    var remote: Bool
    var headers: [ServerHeader] = []

    // `headers` is left out on purpose: values are secrets and live in the Keychain, not UserDefaults.
    private enum CodingKeys: String, CodingKey {
        case label, scheme, address, remote
    }

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
        !label.isEmpty && baseURL != nil
    }

    var iconSystemName: String {
        remote ? "globe" : "house"
    }

    init(_ scheme: AddressScheme, _ address: String, remote: Bool = false, label: String = "") {
        self.scheme = scheme
        self.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.remote = remote
        self.label = label.isEmpty ? address : label
    }
}
