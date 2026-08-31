import Foundation
import Testing
@testable import MyHomeApp

struct DeviceDraftTests {
    // MARK: - init(device:)

    @Test
    func seedsEveryFieldFromTheDevice() {
        let device = Device.fixture(name: "Office LED", brand: .tuya)
            .inRoom(.office)
            .asTuya(deviceId: "abc", localKey: "key", ip: "192.168.0.10")
            .build()

        let draft = DeviceDraft(device: device)

        #expect(draft.name == "Office LED")
        #expect(draft.room == .office)
        #expect(draft.brand == .tuya)
        #expect(draft.transportProtocol == .tuya)
        #expect(draft.ip == "192.168.0.10")
        #expect(draft.tuyaDeviceId == "abc")
        #expect(draft.tuyaDeviceLocalKey == "key")
    }

    @Test
    func seedsMissingOptionalFieldsAsEmptyText() {
        let draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())

        #expect(draft.ip.isEmpty)
        #expect(draft.updateInterval.isEmpty)
        #expect(draft.zigbeeFriendlyName.isEmpty)
    }

    @Test
    func seedsTheUpdateIntervalAsText() {
        let device = Device.fixture(name: "Fans", type: .fans, brand: .esp32)
            .asHTTP(ip: "192.168.0.10", updateInterval: 30_000)
            .build()

        #expect(DeviceDraft(device: device).updateInterval == "30000")
    }

    // MARK: - Applicable fields

    @Test
    func showsTuyaFieldsOnlyForTheTuyaProtocol() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())

        draft.transportProtocol = .tuya
        #expect(draft.showsTuyaFields)
        #expect(draft.showsIPField)

        draft.transportProtocol = .http
        #expect(draft.showsTuyaFields == false)
    }

    @Test
    func showsZigbeeFieldsOnlyForTheZigbeeProtocol() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())

        draft.transportProtocol = .zigbee
        #expect(draft.showsZigbeeFields)
        #expect(draft.showsIPField == false)
        #expect(draft.showsUpdateIntervalField == false)
    }

    // MARK: - Validation

    @Test
    func acceptsANameInsideTheHubsBounds() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.name = "Kitchen ceiling light"

        #expect(draft.error(for: .name) == nil)
    }

    @Test
    func rejectsANameShorterThanTheHubAllows() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.name = "AB"

        #expect(draft.error(for: .name) == "Name must be 3–40 characters.")
        #expect(draft.isValid == false)
    }

    @Test
    func rejectsANameLongerThanTheHubAllows() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.name = String(repeating: "a", count: 41)

        #expect(draft.error(for: .name) != nil)
        #expect(draft.exceedsLimit(.name))
    }

    @Test
    func rejectsAMalformedIPAddress() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.transportProtocol = .http
        draft.ip = "192.168.0"

        #expect(draft.error(for: .ip) != nil)
    }

    @Test
    func acceptsABlankIPAddress() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.transportProtocol = .http
        draft.ip = ""

        #expect(draft.error(for: .ip) == nil)
    }

    @Test
    func ignoresTheIPAddressOfAZigbeeDevice() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.transportProtocol = .zigbee
        draft.ip = "not-an-ip"

        #expect(draft.error(for: .ip) == nil)
    }

    @Test
    func rejectsANonNumericUpdateInterval() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.updateInterval = "soon"

        #expect(draft.error(for: .updateInterval) != nil)
    }

    @Test
    func rejectsANegativeUpdateInterval() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.updateInterval = "-1"

        #expect(draft.error(for: .updateInterval) != nil)
    }

    @Test
    func requiresTheTuyaCredentialsOfATuyaDevice() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.transportProtocol = .tuya

        #expect(draft.error(for: .tuyaDeviceId) != nil)
        #expect(draft.error(for: .tuyaDeviceLocalKey) != nil)
    }

    @Test
    func rejectsAZigbeeFriendlyNameTheHubsPatternRefuses() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.transportProtocol = .zigbee
        draft.zigbeeFriendlyName = "main/light"

        #expect(draft.error(for: .zigbeeFriendlyName) != nil)
    }

    @Test
    func acceptsAZigbeeFriendlyNameWithInnerSpaces() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.transportProtocol = .zigbee
        draft.zigbeeFriendlyName = "Main light remote"

        #expect(draft.error(for: .zigbeeFriendlyName) == nil)
    }

    // MARK: - payload

    @Test
    func payloadCarriesTheEditedDetails() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.name = "  Desk lamp  "
        draft.room = .office

        let payload = draft.payload

        #expect(payload.name == "Desk lamp")
        #expect(payload.room == .office)
    }

    @Test
    func payloadLeavesOutFieldsThatDoNotApplyToTheProtocol() {
        var draft = DeviceDraft(
            device: Device.fixture(name: "Lamp", brand: .tuya)
                .asTuya(deviceId: "abc", localKey: "key", ip: "192.168.0.10")
                .build()
        )
        draft.transportProtocol = .zigbee
        draft.zigbeeFriendlyName = "MainLight"

        let payload = draft.payload

        #expect(payload.ip == nil)
        #expect(payload.tuyaDeviceId == nil)
        #expect(payload.tuyaDeviceLocalKey == nil)
        #expect(payload.zigbeeFriendlyName == "MainLight")
    }

    @Test
    func payloadLeavesOutBlankOptionalFields() {
        var draft = DeviceDraft(device: Device.fixture(name: "Lamp").build())
        draft.transportProtocol = .http
        draft.ip = "   "
        draft.updateInterval = ""

        let payload = draft.payload

        #expect(payload.ip == nil)
        #expect(payload.updateInterval == nil)
    }
}
