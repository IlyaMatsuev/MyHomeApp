import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct DevicesViewModelTests {
    private let service: StubDeviceService
    private let toastStore: ToastStore
    private let viewModel: DevicesViewModel

    init() {
        service = StubDeviceService()
        toastStore = ToastStore()
        viewModel = DevicesViewModel(service: service, toastStore: toastStore)
    }

    // MARK: - init

    @Test
    func initDefaultSelectedRoomIsAll() {
        #expect(viewModel.selectedRoom == .all)
    }

    @Test
    func initHonorsSelectedRoomOverride() {
        let viewModel = DevicesViewModel(service: service, toastStore: toastStore, selectedRoom: .specific(.kitchen))
        #expect(viewModel.selectedRoom == .specific(.kitchen))
    }

    // MARK: - load() — state transitions

    @Test
    func loadWhenServiceSucceedsSetsLoadedState() async {
        service.setDevices([
            Device.fixture().inRoom(.livingRoom).build(),
        ])

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(service.fetchDevicesCallCount == 1)
    }

    @Test
    func loadWhenServiceFailsSetsFailedStateWithMessage() async {
        struct SampleError: LocalizedError {
            var errorDescription: String? { "Boom" }
        }
        service.setDevicesError(SampleError())

        await viewModel.load()

        #expect(viewModel.state == .failed("Boom"))
        #expect(viewModel.roomGroups.isEmpty)
    }

    @Test
    func loadWithEmptyResponseSetsLoadedWithEmptyGroups() async {
        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.roomGroups.isEmpty)
    }

    // MARK: - load() — grouping

    @Test
    func loadGroupsDevicesByRoom() async throws {
        service.setDevices([
            Device.fixture(name: "Lamp").inRoom(.livingRoom).build(),
            Device.fixture(name: "Speaker").inRoom(.livingRoom).build(),
            Device.fixture(name: "Switch").inRoom(.bedroom).build(),
        ])

        await viewModel.load()

        #expect(viewModel.roomGroups.count == 2)
        let livingRoom = try #require(viewModel.roomGroups.first { $0.room == .livingRoom })
        let bedroom = try #require(viewModel.roomGroups.first { $0.room == .bedroom })
        #expect(livingRoom.devices.count == 2)
        #expect(bedroom.devices.count == 1)
    }

    @Test
    func loadSortsGroupsByRoomWithGeneralFirst() async {
        service.setDevices([
            Device.fixture().inRoom(.office).build(),
            Device.fixture().inRoom(.general).build(),
            Device.fixture().inRoom(.livingRoom).build(),
        ])

        await viewModel.load()

        #expect(viewModel.roomGroups.map(\.room) == [.general, .livingRoom, .office])
    }

    @Test
    func loadSortsDevicesWithinAGroup() async throws {
        service.setDevices([
            Device.fixture(name: "Zebra Lamp").inRoom(.livingRoom).build(),
            Device.fixture(name: "Alpha Lamp").inRoom(.livingRoom).build(),
            Device.fixture(name: "Mid Lamp").inRoom(.livingRoom).build(),
        ])

        await viewModel.load()

        let roomGroup = try #require(viewModel.roomGroups.first)
        let names = roomGroup.devices.map(\.name)
        #expect(
            names == names.sorted(),
            "Devices within a group should be sorted by Device's Comparable conformance"
        )
    }

    // MARK: - load() — selection persistence

    @Test
    func loadDoesNotChangeSelectedRoom() async {
        viewModel.selectedRoom = .specific(.kitchen)
        service.setDevices([
            Device.fixture().inRoom(.livingRoom).build(),
        ])

        await viewModel.load()

        #expect(viewModel.selectedRoom == .specific(.kitchen))
    }

    // MARK: - availableRooms

    @Test
    func availableRoomsAfterLoadContainsOnlyRoomsWithDevices() async {
        service.setDevices([
            Device.fixture(name: "Lamp").inRoom(.livingRoom).build(),
            Device.fixture(name: "Speaker").inRoom(.livingRoom).build(),
            Device.fixture(name: "Switch").inRoom(.bedroom).build(),
        ])

        await viewModel.load()

        #expect(viewModel.availableRooms == [.bedroom, .livingRoom])
    }

    @Test
    func availableRoomsMatchesRoomGroupsOrder() async {
        service.setDevices([
            Device.fixture().inRoom(.office).build(),
            Device.fixture().inRoom(.general).build(),
            Device.fixture().inRoom(.bedroom).build(),
        ])

        await viewModel.load()

        #expect(viewModel.availableRooms == viewModel.roomGroups.map(\.room))
    }

    // MARK: - visibleRoomGroups

    @Test
    func visibleRoomGroupsWhenSelectionIsAllReturnsAllGroups() async {
        service.setDevices([
            Device.fixture(name: "Lamp").inRoom(.livingRoom).build(),
            Device.fixture(name: "Switch").inRoom(.bedroom).build(),
        ])
        await viewModel.load()
        viewModel.selectedRoom = .all

        #expect(viewModel.visibleRoomGroups.count == 2)
        #expect(Set(viewModel.visibleRoomGroups.map(\.room)) == [.livingRoom, .bedroom])
    }

    @Test
    func visibleRoomGroupsWhenSpecificRoomSelectedReturnsOnlyThatRoom() async throws {
        service.setDevices([
            Device.fixture(name: "Lamp").inRoom(.livingRoom).build(),
            Device.fixture(name: "Speaker").inRoom(.livingRoom).build(),
            Device.fixture(name: "Switch").inRoom(.bedroom).build(),
        ])
        await viewModel.load()

        viewModel.selectedRoom = .specific(.livingRoom)

        #expect(viewModel.visibleRoomGroups.count == 1)
        let roomGroup = try #require(viewModel.visibleRoomGroups.first)
        #expect(roomGroup.room == .livingRoom)
        #expect(roomGroup.devices.count == 2)
    }

    @Test
    func visibleRoomGroupsWhenSpecificRoomHasNoDevicesReturnsEmpty() async {
        service.setDevices([
            Device.fixture().inRoom(.livingRoom).build(),
        ])
        await viewModel.load()

        viewModel.selectedRoom = .specific(.kitchen)

        #expect(viewModel.visibleRoomGroups.isEmpty)
    }
}
