import Foundation

struct Server: Codable, Equatable, Sendable, Identifiable {
    var addressProtocol: AddressProtocol
    var address: String
    var remote: Bool

    var id: String {
        address
    }

    var baseURL: URL? {
        guard !address.isEmpty else { return nil }
        let raw = "\(addressProtocol)://\(address)"
        guard let components = URLComponents(string: raw), components.host?.isEmpty == false else {
            return nil
        }
        return components.url
    }

    init(_ addressProtocol: AddressProtocol = .http, _ address: String, remote: Bool = false) {
        self.addressProtocol = addressProtocol
        self.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.remote = remote
    }
}
