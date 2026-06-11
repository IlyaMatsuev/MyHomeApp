enum AddressProtocol: String, Codable, Equatable, CaseIterable {
    case http
    case https

    var label: String { rawValue }
}
