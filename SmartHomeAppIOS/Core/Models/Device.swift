import Foundation
import AnyCodable

struct Device: Codable, Identifiable, Hashable {
    let externalId: String
    let name: String

    let type: DeviceType
    let brand: DeviceBrand
    let room: DeviceRoom

    let transportProtocol: TransportProtocol
    let ip: String?
    let updateInterval: Int?

    let tuyaDeviceId: String?
    let tuyaDeviceLocalKey: String?

    let zigbeeFriendlyName: String?
    let zigbeeIeeeAddress: String?

    let controls: [String: AnyCodable]?
    let measurements: [String: AnyCodable]?

    let controlsUpdatedAt: Date?
    let measurementsUpdatedAt: Date?

    let createdAt: Date
    let updatedAt: Date

    var id: String { externalId }
}

extension Device: Comparable {
    static func < (lhs: Device, rhs: Device) -> Bool {
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}
