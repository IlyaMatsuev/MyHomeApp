import Foundation
import AnyCodable
@testable import MyHomeApp

extension Device {
    /// Entry point for the fluent device fixture builder.
    ///
    /// ```swift
    /// let lamp = Device.fixture(name: "Lamp", type: .led, brand: .tuya)
    ///     .inRoom(.kitchen)
    ///     .asTuya(deviceId: "abc", localKey: "key", ip: "192.168.0.10")
    ///     .withControls(["on": true])
    ///     .build()
    /// ```
    static func fixture(
        name: String = "Test Device",
        type: DeviceType = .led,
        brand: DeviceBrand = .philips
    ) -> DeviceFixtureBuilder {
        DeviceFixtureBuilder(name: name, type: type, brand: brand)
    }
}

final class DeviceFixtureBuilder {
    private var externalId = UUID().uuidString
    private let name: String
    private let type: DeviceType
    private let brand: DeviceBrand

    private var room: DeviceRoom = .general
    private var transportProtocol: TransportProtocol = .http
    private var ip: String?
    private var updateInterval: Int?

    private var tuyaDeviceId: String?
    private var tuyaDeviceLocalKey: String?

    private var zigbeeFriendlyName: String?
    private var zigbeeIeeeAddress: String?

    private var controls: [String: AnyCodable] = [:]
    private var controlsUpdatedAt: Date?
    private var measurements: [String: AnyCodable] = [:]
    private var measurementsUpdatedAt: Date?

    private var config: DeviceConfig?

    private var createdAt = Date(timeIntervalSince1970: 0)
    private var updatedAt = Date(timeIntervalSince1970: 0)

    fileprivate init(
        name: String,
        type: DeviceType,
        brand: DeviceBrand,
    ) {
        self.name = name
        self.type = type
        self.brand = brand
    }

    /// Pins the identity, so a test can build a second version of the same device.
    func withId(_ externalId: String) -> Self {
        self.externalId = externalId
        return self
    }

    func inRoom(_ room: DeviceRoom) -> Self {
        self.room = room
        return self
    }

    func asTuya(deviceId: String, localKey: String, ip: String? = nil) -> Self {
        transportProtocol = .tuya
        tuyaDeviceId = deviceId
        tuyaDeviceLocalKey = localKey
        self.ip = ip
        return self
    }

    func asZigbee(friendlyName: String, ieeeAddress: String) -> Self {
        transportProtocol = .zigbee
        zigbeeFriendlyName = friendlyName
        zigbeeIeeeAddress = ieeeAddress
        return self
    }

    func asHTTP(ip: String, updateInterval: Int? = nil) -> Self {
        transportProtocol = .http
        self.ip = ip
        self.updateInterval = updateInterval
        return self
    }

    func withControls(
        _ controls: [String: AnyCodable],
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        self.controls = controls
        controlsUpdatedAt = updatedAt
        return self
    }

    func withMeasurements(
        _ measurements: [String: AnyCodable],
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        self.measurements = measurements
        measurementsUpdatedAt = updatedAt
        return self
    }

    func withConfig(_ config: DeviceConfig) -> Self {
        self.config = config
        return self
    }

    func withTimestamps(createdAt: Date, updatedAt: Date) -> Self {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        return self
    }

    func build() -> Device {
        Device(
            externalId: externalId,
            name: name,
            type: type,
            brand: brand,
            room: room,
            transportProtocol: transportProtocol,
            ip: ip,
            updateInterval: updateInterval,
            tuyaDeviceId: tuyaDeviceId,
            tuyaDeviceLocalKey: tuyaDeviceLocalKey,
            zigbeeFriendlyName: zigbeeFriendlyName,
            zigbeeIeeeAddress: zigbeeIeeeAddress,
            controls: controls,
            measurements: measurements,
            config: config,
            controlsUpdatedAt: controlsUpdatedAt,
            measurementsUpdatedAt: measurementsUpdatedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
