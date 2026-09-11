import Testing
@testable import MyHomeApp

/// Navigation state for the devices tab: which destination is presented, and clearing it.
@MainActor
struct DevicesRouterTests {
    private let router = DevicesRouter()

    @Test
    func startsWithNoDestination() {
        #expect(router.destination == nil)
    }

    @Test
    func editingADeviceSetsTheEditDestination() {
        let lamp = Device.fixture(name: "Lamp").build()

        router.editDevice(lamp)

        #expect(router.destination == .edit(deviceId: lamp.id))
    }

    @Test
    func dismissingClearsTheDestination() {
        router.editDevice(Device.fixture(name: "Lamp").build())

        router.dismiss()

        #expect(router.destination == nil)
    }
}
