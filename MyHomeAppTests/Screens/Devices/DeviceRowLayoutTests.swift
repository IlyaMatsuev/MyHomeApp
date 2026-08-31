import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

struct DeviceRowLayoutTests {
    // MARK: - Promoted controls

    @Test
    func promotesOnlyTheMainControlsIntoTheRow() {
        let device = Device.fixture(name: "LED", brand: .shelly)
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": true, "brightness": 60])
            .build()

        #expect(DeviceRowLayout.controlItems(of: device).map(\.name) == ["on", "brightness"])
    }

    @Test
    func leavesADeviceWithoutMainControlsWithAnEmptyRow() {
        let device = Device.fixture(name: "Remote", type: .remote, brand: .philips)
            .withConfig(MockDeviceConfigs.philipsRemote)
            .build()

        #expect(DeviceRowLayout.controlItems(of: device).isEmpty)
    }

    @Test
    func skipsAMainControlTheAppHasNoEditorFor() {
        let config = DeviceConfig(
            commands: nil,
            controls: [DeviceConfigItem(label: "On", name: "on", type: .object)],
            measurements: nil
        )
        let device = Device.fixture(name: "Odd").withConfig(config).build()

        #expect(DeviceRowLayout.controlItems(of: device).isEmpty)
    }

    // MARK: - Promoted commands

    @Test
    func promotesTheTextCommandOfASpeaker() {
        let device = Device.fixture(name: "Nest", type: .speaker, brand: .google)
            .withConfig(MockDeviceConfigs.googleSpeaker)
            .build()

        #expect(DeviceRowLayout.commandItems(of: device).map(\.name) == ["text"])
    }

    @Test
    func leavesOtherCommandsToTheDeviceSheet() {
        let device = Device.fixture(name: "Remote", type: .remote, brand: .philips)
            .withConfig(MockDeviceConfigs.philipsRemote)
            .build()

        #expect(DeviceRowLayout.commandItems(of: device).isEmpty)
    }

    // MARK: - Measurements summary

    @Test
    func summarisesEveryMeasurementWithItsLabel() {
        let device = Device.fixture(name: "Remote", type: .remote, brand: .philips)
            .withConfig(MockDeviceConfigs.philipsRemote)
            .withMeasurements(["battery": 100, "linkquality": 204])
            .build()

        #expect(DeviceRowLayout.measurementsSummary(of: device) == "Battery level 100 · Connection quality 204")
    }

    @Test
    func skipsMeasurementsTheDeviceHasNotReportedYet() {
        let device = Device.fixture(name: "Plug", type: .plug, brand: .shelly)
            .withConfig(MockDeviceConfigs.shellyPlug)
            .withMeasurements(["power": 27.5])
            .build()

        #expect(DeviceRowLayout.measurementsSummary(of: device) == "Power 27.5")
    }

    @Test
    func summarisesNothingWhenThereAreNoMeasurements() {
        let device = Device.fixture(name: "LED", brand: .tuya)
            .withConfig(MockDeviceConfigs.tuyaLED)
            .withControls(["on": true])
            .build()

        #expect(DeviceRowLayout.measurementsSummary(of: device) == nil)
    }
}
