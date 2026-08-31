import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

/// How a `Device` turns its config (or the lack of one) into the items a screen renders.
struct DeviceConfigLayoutTests {
    // MARK: - Declared config

    @Test
    func controlItemsFollowTheOrderTheConfigDeclares() {
        let device = Device.fixture(name: "LED", brand: .shelly)
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": true, "brightness": 60])
            .build()

        let expected = ["on", "mode", "brightness", "color", "temperature", "transitionDuration"]
        #expect(device.controlItems.map(\.name) == expected)
    }

    @Test
    func measurementItemsComeFromTheConfig() {
        let device = Device.fixture(name: "Remote", type: .remote, brand: .philips)
            .withConfig(MockDeviceConfigs.philipsRemote)
            .withMeasurements(["battery": 100, "linkquality": 204])
            .build()

        #expect(device.measurementItems.map(\.name) == ["battery", "linkquality"])
    }

    @Test
    func commandItemsComeFromTheConfig() {
        let device = Device.fixture(name: "Nest", type: .speaker, brand: .google)
            .withConfig(MockDeviceConfigs.googleSpeaker)
            .build()

        #expect(device.commandItems.map(\.name) == ["text"])
    }

    @Test
    func controlAndMeasurementValuesAreReadByItemName() throws {
        let device = Device.fixture(name: "Plug", type: .plug, brand: .shelly)
            .withConfig(MockDeviceConfigs.shellyPlug)
            .withControls(["on": true])
            .withMeasurements(["power": 27.5])
            .build()

        let onControl = try #require(device.controlItems.first { $0.name == "on" })
        let power = try #require(device.measurementItems.first { $0.name == "power" })
        #expect(DeviceConfigValue.bool(device.controlValue(of: onControl)) == true)
        #expect(DeviceConfigValue.number(device.measurementValue(of: power)) == 27.5)
    }

    // MARK: - No config shipped

    @Test
    func infersControlItemsFromTheStoredPayloadWhenTheHubShipsNoConfig() throws {
        let device = Device.fixture(name: "Unknown")
            .withControls(["on": true, "speedPercentage": 40])
            .build()

        #expect(device.controlItems.map(\.name) == ["on", "speedPercentage"])
        let inferred = try #require(device.controlItems.last)
        #expect(inferred.type == .number)
        #expect(inferred.label == "Speed percentage")
    }

    @Test
    func infersItemTypesFromTheStoredValues() throws {
        let device = Device.fixture(name: "Unknown")
            .withControls(["flag": true, "count": 3, "note": "hi"])
            .build()

        let byName = Dictionary(uniqueKeysWithValues: device.controlItems.map { ($0.name, $0.type) })
        #expect(byName["flag"] == .boolean)
        #expect(byName["count"] == .number)
        #expect(byName["note"] == .string)
    }

    @Test
    func infersNothingForCommands() {
        let device = Device.fixture(name: "Unknown").withControls(["on": true]).build()

        #expect(device.commandItems.isEmpty)
    }

    @Test
    func hasNoItemsWhenThereIsNeitherConfigNorPayload() {
        let device = Device.fixture(name: "Unknown").build()

        #expect(device.controlItems.isEmpty)
        #expect(device.measurementItems.isEmpty)
    }

    // MARK: - Carrying the config across mutations

    @Test
    func preservingConfigFillsInAConfigTheMutationResponseOmitted() {
        let known = Device.fixture(name: "LED", brand: .tuya)
            .withConfig(MockDeviceConfigs.tuyaLED)
            .withControls(["on": false])
            .build()
        var fromHub = known
        fromHub.config = nil
        fromHub.controls = ["on": true]

        let merged = fromHub.preservingConfig(from: known)

        #expect(merged.config == MockDeviceConfigs.tuyaLED)
        #expect(DeviceConfigValue.bool(merged.controls?["on"]) == true)
    }

    @Test
    func preservingConfigKeepsAFreshConfigTheHubDidSend() {
        let previous = Device.fixture(name: "LED", brand: .tuya).withConfig(MockDeviceConfigs.tuyaLED).build()
        var fromHub = previous
        fromHub.config = MockDeviceConfigs.shellyLED

        #expect(fromHub.preservingConfig(from: previous).config == MockDeviceConfigs.shellyLED)
    }
}
