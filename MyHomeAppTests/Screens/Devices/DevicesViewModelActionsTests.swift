import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

/// The list screen acting on a device: staging and committing controls, firing commands, and
/// keeping the list in step with the device sheet.
@MainActor
struct DevicesViewModelActionsTests {
    private let service: StubDeviceService
    private let toastStore: ToastStore
    private let viewModel: DevicesViewModel

    init() {
        service = StubDeviceService()
        toastStore = ToastStore()
        viewModel = DevicesViewModel(service: service, toastStore: toastStore)
    }

    // MARK: - Controls

    @Test
    func stagingAControlUpdatesTheRowWithoutContactingTheHub() async throws {
        let lamp = Device.fixture(name: "Lamp", brand: .shelly)
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": false, "brightness": 20])
            .build()
        service.setDevices([lamp])
        await viewModel.load()

        viewModel.stageControl(lamp.id, name: "brightness", value: AnyCodable(70))

        let staged = try #require(viewModel.device(withId: lamp.id))
        #expect(DeviceConfigValue.number(staged.controls?["brightness"]) == 70)
        #expect(service.updateControlsCalls.isEmpty)
    }

    @Test
    func committingAControlSendsTheStagedValue() async throws {
        let lamp = Device.fixture(name: "Lamp", brand: .shelly)
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": false, "brightness": 20])
            .build()
        service.setDevices([lamp])
        service.echo(lamp)
        await viewModel.load()

        viewModel.stageControl(lamp.id, name: "brightness", value: AnyCodable(70))
        await viewModel.commitControl(lamp.id, name: "brightness")

        #expect(service.updateControlsCalls.count == 1)
        #expect(service.updateControlsCalls.first?.controls == ["brightness": AnyCodable(70)])
    }

    @Test
    func aFailedControlUpdateRestoresTheValueTheDragStartedFrom() async throws {
        let lamp = Device.fixture(name: "Lamp", brand: .shelly)
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": false, "brightness": 20])
            .build()
        service.setDevices([lamp])
        service.updateControlsResult = { _ in .failure(HubAPIError.transport) }
        await viewModel.load()

        viewModel.stageControl(lamp.id, name: "brightness", value: AnyCodable(45))
        viewModel.stageControl(lamp.id, name: "brightness", value: AnyCodable(70))
        await viewModel.commitControl(lamp.id, name: "brightness")

        let restored = try #require(viewModel.device(withId: lamp.id))
        #expect(DeviceConfigValue.number(restored.controls?["brightness"]) == 20)
        #expect(toastStore.current?.kind == .error)
    }

    @Test
    func aSuccessfulControlUpdateKeepsTheConfigTheResponseOmitted() async throws {
        let lamp = Device.fixture(name: "Lamp", brand: .shelly)
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": false])
            .build()
        var echoed = lamp
        echoed.config = nil
        echoed.controls = ["on": true]
        service.setDevices([lamp])
        service.updateControlsResult = { _ in .success(echoed) }
        await viewModel.load()

        viewModel.stageControl(lamp.id, name: "on", value: AnyCodable(true))
        await viewModel.commitControl(lamp.id, name: "on")

        let updated = try #require(viewModel.device(withId: lamp.id))
        #expect(updated.config == MockDeviceConfigs.shellyLED)
        #expect(DeviceConfigValue.bool(updated.controls?["on"]) == true)
    }

    @Test
    func doesNothingWhenCommittingAControlOfAnUnknownDevice() async {
        await viewModel.commitControl("nope", name: "on")

        #expect(service.updateControlsCalls.isEmpty)
    }

    @Test
    func aFailedControlUpdateLeavesOtherControlsAlone() async throws {
        let lamp = Device.fixture(name: "Lamp", brand: .shelly)
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": false, "brightness": 20])
            .build()
        service.setDevices([lamp])
        service.updateControlsResult = { _ in .failure(HubAPIError.transport) }
        await viewModel.load()

        // The user drags brightness, then flips the switch before the drag is committed.
        viewModel.stageControl(lamp.id, name: "brightness", value: AnyCodable(70))
        viewModel.stageControl(lamp.id, name: "on", value: AnyCodable(true))
        await viewModel.commitControl(lamp.id, name: "brightness")

        let device = try #require(viewModel.device(withId: lamp.id))
        #expect(DeviceConfigValue.number(device.controls?["brightness"]) == 20)
        #expect(
            DeviceConfigValue.bool(device.controls?["on"]) == true,
            "The other staged control must survive the rollback"
        )
    }

    @Test
    func aFailedControlUpdateRemovesAControlTheDeviceNeverHad() async throws {
        let lamp = Device.fixture(name: "Lamp", brand: .shelly)
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": false])
            .build()
        service.setDevices([lamp])
        service.updateControlsResult = { _ in .failure(HubAPIError.transport) }
        await viewModel.load()

        viewModel.stageControl(lamp.id, name: "brightness", value: AnyCodable(70))
        await viewModel.commitControl(lamp.id, name: "brightness")

        let device = try #require(viewModel.device(withId: lamp.id))
        #expect(device.controls?["brightness"] == nil)
    }

    // MARK: - Commands

    @Test
    func sendingACommandToastsSuccess() async {
        let speaker = Device.fixture(name: "Nest", type: .speaker, brand: .google)
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.googleSpeaker)
            .build()
        service.setDevices([speaker])
        service.echo(speaker)
        await viewModel.load()

        await viewModel.sendCommand(speaker.id, name: "text", value: AnyCodable("Hello"), label: "Text-to-speech")

        #expect(service.sendCommandCalls.first?.command == ["text": AnyCodable("Hello")])
        #expect(toastStore.current?.kind == .success)
    }

    @Test
    func aFailedCommandToastsAnError() async {
        let speaker = Device.fixture(name: "Nest", type: .speaker, brand: .google)
            .inRoom(.livingRoom)
            .withConfig(MockDeviceConfigs.googleSpeaker)
            .build()
        service.setDevices([speaker])
        service.sendCommandResult = { _ in .failure(HubAPIError.transport) }
        await viewModel.load()

        await viewModel.sendCommand(speaker.id, name: "text", value: AnyCodable("Hello"), label: "Text-to-speech")

        #expect(toastStore.current?.kind == .error)
    }

    // MARK: - Device sheet

    @Test
    func openingADeviceCreatesTheSheetViewModel() async {
        let lamp = Device.fixture(name: "Lamp").inRoom(.livingRoom).build()
        service.setDevices([lamp])
        await viewModel.load()

        viewModel.openDetail(lamp)

        #expect(viewModel.detail?.device.id == lamp.id)
    }

    @Test
    func closingTheSheetClearsIt() async {
        let lamp = Device.fixture(name: "Lamp").inRoom(.livingRoom).build()
        service.setDevices([lamp])
        await viewModel.load()
        viewModel.openDetail(lamp)

        viewModel.closeDetail()

        #expect(viewModel.detail == nil)
    }

    @Test
    func deletingFromTheSheetRemovesTheRowAndClosesIt() async throws {
        let lamp = Device.fixture(name: "Lamp").inRoom(.livingRoom).build()
        let speaker = Device.fixture(name: "Speaker").inRoom(.livingRoom).build()
        service.setDevices([lamp, speaker])
        await viewModel.load()
        viewModel.openDetail(lamp)

        let detail = try #require(viewModel.detail)
        await detail.confirmDeletion()

        #expect(viewModel.roomGroups.flatMap(\.devices).map(\.id) == [speaker.id])
        #expect(viewModel.detail == nil)
    }

    @Test
    func savingFromTheSheetMovesTheRowToItsNewRoom() async throws {
        let lamp = Device.fixture(name: "Lamp").inRoom(.livingRoom).build()
        service.setDevices([lamp])
        let moved = Device.fixture(name: "Lamp").withId(lamp.id).inRoom(.office).build()
        service.updateDeviceResult = { _ in .success(moved) }
        await viewModel.load()
        viewModel.openDetail(lamp)

        let detail = try #require(viewModel.detail)
        detail.draft.name = "Desk lamp"
        await detail.saveDetails()

        #expect(viewModel.availableRooms == [.office])
    }
}
