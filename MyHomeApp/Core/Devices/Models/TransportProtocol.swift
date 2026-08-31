enum TransportProtocol: String, Codable, Hashable, CaseIterable {
    case http
    case mqtt
    case tuya
    case zigbee
}

extension TransportProtocol {
    var label: String {
        switch self {
        case .http: return ("HTTP")
        case .mqtt: return ("MQTT")
        case .tuya: return ("Tuya")
        case .zigbee: return ("Zigbee")
        }
    }
}
