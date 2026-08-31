import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

@MainActor
struct DeviceDetailViewModelTests {
    private let service: StubDeviceService
    private let toastStore: ToastStore
    private let device: Device

    init() {
        service = StubDeviceService()
        toastStore = ToastStore()
        device = Device.fixture(name: "Office LED", brand: .shelly)
            .inRoom(.office)
            .asHTTP(ip: "192.168.0.10")
            .withConfig(MockDeviceConfigs.shellyLED)
            .withControls(["on": false, "brightness": 60, "mode": "cct"])
            .withMeasurements(["power": 8.4])
            .build()
    }

    private func makeViewModel(
        onChanged: @escaping @MainActor (Device) -> Void = { _ in },
        onDeleted: @escaping @MainActor (String) -> Void = { _ in }
    ) -> DeviceDetailViewModel {
        DeviceDetailViewModel(
            device: device,
            service: service,
            toastStore: toastStore,
            onChanged: onChanged,
            onDeleted: onDeleted
        )
    }

    // MARK: - init

    @Test
    func seedsControlDraftsFromTheStoredValues() throws {
        let viewModel = makeViewModel()

        let brightness = try #require(viewModel.controlItems.first { $0.name == "brightness" })
        #expect(DeviceConfigValue.number(viewModel.controlValue(of: brightness)) == 60)
        #expect(viewModel.isControlDirty(brightness) == false)
    }

    @Test
    func seedsAnUnsetControlWithItsFallbackValue() throws {
        let viewModel = makeViewModel()

        let temperature = try #require(viewModel.controlItems.first { $0.name == "temperature" })
        #expect(DeviceConfigValue.number(viewModel.controlValue(of: temperature)) == 2700)
    }

    @Test
    func seedsCommandDraftsFromTheConfigDefaults() throws {
        let speaker = Device.fixture(name: "Nest", type: .speaker, brand: .google)
            .withConfig(MockDeviceConfigs.googleSpeaker)
            .build()
        let viewModel = DeviceDetailViewModel(
            device: speaker,
            service: service,
            toastStore: toastStore,
            onChanged: { _ in },
            onDeleted: { _ in }
        )

        let text = try #require(viewModel.commandItems.first)
        #expect(DeviceConfigValue.string(viewModel.commandValue(of: text)) == "")
    }

    // MARK: - Details

    @Test
    func staysQuietAboutAFieldUntilTheFirstSaveAttempt() {
        let viewModel = makeViewModel()
        viewModel.draft.name = "AB"

        #expect(viewModel.detailsError(for: .name) == nil)
    }

    @Test
    func complainsAboutAnOverrunFieldBeforeAnySaveAttempt() {
        let viewModel = makeViewModel()
        viewModel.draft.name = String(repeating: "a", count: 41)

        #expect(viewModel.detailsError(for: .name) != nil)
    }

    @Test
    func complainsAboutEveryInvalidFieldAfterASaveAttempt() async {
        let viewModel = makeViewModel()
        viewModel.draft.name = "AB"

        await viewModel.saveDetails()

        #expect(viewModel.detailsError(for: .name) != nil)
        #expect(service.updateDeviceCalls.isEmpty)
    }

    @Test
    func cannotSaveWithoutChanges() {
        #expect(makeViewModel().canSaveDetails == false)
    }

    @Test
    func canSaveOnceAFieldChanges() {
        let viewModel = makeViewModel()
        viewModel.draft.name = "Desk lamp"

        #expect(viewModel.canSaveDetails)
    }

    @Test
    func savingSendsThePayloadAndAdoptsTheHubsAnswer() async throws {
        var updated = device
        updated.config = nil
        service.updateDeviceResult = { _ in .success(updated) }

        var changed: Device?
        let viewModel = makeViewModel(onChanged: { changed = $0 })
        viewModel.draft.name = "Desk lamp"

        await viewModel.saveDetails()

        #expect(service.updateDeviceCalls.count == 1)
        #expect(service.updateDeviceCalls.first?.payload.name == "Desk lamp")
        #expect(changed?.id == device.id)
        #expect(viewModel.isSavingDetails == false)
    }

    @Test
    func savingKeepsTheConfigTheMutationResponseOmitted() async {
        var updated = device
        updated.config = nil
        service.updateDeviceResult = { _ in .success(updated) }

        let viewModel = makeViewModel()
        viewModel.draft.name = "Desk lamp"

        await viewModel.saveDetails()

        #expect(viewModel.device.config == MockDeviceConfigs.shellyLED)
        #expect(viewModel.controlItems.isEmpty == false)
    }

    @Test
    func savingSurfacesTheHubsValidationMessage() async {
        service.updateDeviceResult = { _ in .failure(HubAPIError.validation("name", "Name is taken")) }

        let viewModel = makeViewModel()
        viewModel.draft.name = "Desk lamp"

        await viewModel.saveDetails()

        #expect(viewModel.detailsErrorMessage == "Name is taken")
    }

    @Test
    func resettingDetailsDropsTheEdits() {
        let viewModel = makeViewModel()
        viewModel.draft.name = "Desk lamp"

        viewModel.resetDetails()

        #expect(viewModel.draft.name == "Office LED")
        #expect(viewModel.canSaveDetails == false)
    }

    // MARK: - Controls
    @Test
    func aControlUpdateKeepsTheDetailsTheUserIsStillTyping() async throws {
        service.updateControlsResult = { _ in .success(self.device) }
        let viewModel = makeViewModel()
        let brightness = try #require(viewModel.controlItems.first { $0.name == "brightness" })

        viewModel.draft.name = "Half-typed nam"
        viewModel.setControlValue(AnyCodable(80), of: brightness)
        await viewModel.commitControl(brightness)

        #expect(viewModel.draft.name == "Half-typed nam")
    }

    @Test
    func committingAControlSendsOnlyThatControl() async throws {
        service.updateControlsResult = { _ in .success(self.device) }
        let viewModel = makeViewModel()
        let brightness = try #require(viewModel.controlItems.first { $0.name == "brightness" })

        viewModel.setControlValue(AnyCodable(80), of: brightness)
        await viewModel.commitControl(brightness)

        #expect(service.updateControlsCalls.count == 1)
        #expect(service.updateControlsCalls.first?.controls == ["brightness": AnyCodable(80)])
    }

    @Test
    func doesNotSendAControlThatDidNotChange() async throws {
        let viewModel = makeViewModel()
        let brightness = try #require(viewModel.controlItems.first { $0.name == "brightness" })

        await viewModel.commitControl(brightness)

        #expect(service.updateControlsCalls.isEmpty)
    }

    @Test
    func doesNotSendAControlTheHubWouldReject() async throws {
        let viewModel = makeViewModel()
        let brightness = try #require(viewModel.controlItems.first { $0.name == "brightness" })

        viewModel.setControlValue(AnyCodable(140), of: brightness)

        #expect(viewModel.controlError(of: brightness) != nil)
        await viewModel.commitControl(brightness)
        #expect(service.updateControlsCalls.isEmpty)
    }

    @Test
    func aFailedControlUpdateRollsTheDraftBackAndToasts() async throws {
        service.updateControlsResult = { _ in .failure(HubAPIError.transport) }
        let viewModel = makeViewModel()
        let brightness = try #require(viewModel.controlItems.first { $0.name == "brightness" })

        viewModel.setControlValue(AnyCodable(80), of: brightness)
        await viewModel.commitControl(brightness)

        #expect(DeviceConfigValue.number(viewModel.controlValue(of: brightness)) == 60)
        #expect(toastStore.current?.kind == .error)
    }
}
