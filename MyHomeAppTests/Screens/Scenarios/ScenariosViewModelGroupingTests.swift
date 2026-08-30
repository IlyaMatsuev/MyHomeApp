import Foundation
import Testing
@testable import MyHomeApp

/// Sectioning and filtering of the loaded scenarios by their hub `group`.
@MainActor
struct ScenariosViewModelGroupingTests {
    private let service: StubScenarioService
    private let viewModel: ScenariosViewModel

    init() {
        service = StubScenarioService()
        viewModel = ScenariosViewModel(
            service: service,
            deviceService: StubDeviceService(),
            toastStore: ToastStore()
        )
    }

    // MARK: - grouping

    @Test
    func loadGroupsScenariosByTheirGroup() async throws {
        service.setScenarios([
            Scenario.fixture(name: "Warm light on").inGroup("living_room").build(),
            Scenario.fixture(name: "Movie time").inGroup("living_room").build(),
            Scenario.fixture(name: "Wake up").inGroup("bedroom").build()
        ])

        await viewModel.load()

        #expect(viewModel.groupSections.count == 2)
        let livingRoom = try #require(viewModel.groupSections.first { $0.group == "living_room" })
        let bedroom = try #require(viewModel.groupSections.first { $0.group == "bedroom" })
        #expect(livingRoom.scenarios.count == 2)
        #expect(bedroom.scenarios.count == 1)
    }

    @Test
    func scenariosWithoutAGroupLandInTheUngroupedSection() async throws {
        service.setScenarios([Scenario.fixture(name: "Nightly reboot").build()])

        await viewModel.load()

        let section = try #require(viewModel.groupSections.first)
        #expect(section.group == nil)
        #expect(section.title == "Ungrouped")
    }

    @Test
    func loadSortsSectionsWithUngroupedFirst() async {
        service.setScenarios([
            Scenario.fixture(name: "Away").inGroup("office").build(),
            Scenario.fixture(name: "Nightly reboot").build(),
            Scenario.fixture(name: "Movie time").inGroup("living_room").build()
        ])

        await viewModel.load()

        #expect(viewModel.groupSections.map(\.title) == ["Ungrouped", "Living Room", "Office"])
    }

    @Test
    func loadSortsScenariosWithinASection() async throws {
        service.setScenarios([
            Scenario.fixture(name: "Zebra").inGroup("living_room").build(),
            Scenario.fixture(name: "Alpha").inGroup("living_room").build(),
            Scenario.fixture(name: "Mid").inGroup("living_room").build()
        ])

        await viewModel.load()

        let section = try #require(viewModel.groupSections.first)
        #expect(section.scenarios.map(\.name) == ["Alpha", "Mid", "Zebra"])
    }

    // MARK: - filtering

    @Test
    func groupFiltersOfferAllPlusTheGroupsThatHaveScenarios() async {
        service.setScenarios([
            Scenario.fixture(name: "Movie time").inGroup("living_room").build(),
            Scenario.fixture(name: "Wake up").inGroup("bedroom").build()
        ])

        await viewModel.load()

        #expect(viewModel.groupFilters == [.all, .named("bedroom"), .named("living_room")])
        #expect(viewModel.groupFilters.map(\.label) == ["All", "Bedroom", "Living Room"])
        #expect(viewModel.knownGroups == ["bedroom", "living_room"])
    }

    @Test
    func groupFiltersIncludeUngroupedWhenAScenarioHasNoGroup() async {
        service.setScenarios([
            Scenario.fixture(name: "Nightly reboot").build(),
            Scenario.fixture(name: "Movie time").inGroup("living_room").build()
        ])

        await viewModel.load()

        #expect(viewModel.groupFilters == [.all, .ungrouped, .named("living_room")])
        #expect(viewModel.knownGroups == ["living_room"], "Ungrouped is not a group name the editor can suggest")
    }

    @Test
    func visibleSectionsWhenSelectionIsAllReturnsEverything() async {
        service.setScenarios([
            Scenario.fixture(name: "Movie time").inGroup("living_room").build(),
            Scenario.fixture(name: "Wake up").inGroup("bedroom").build()
        ])
        await viewModel.load()

        viewModel.selectedGroup = .all

        #expect(viewModel.visibleSections.count == 2)
    }

    @Test
    func visibleSectionsWhenASpecificGroupIsSelectedReturnsOnlyThatGroup() async throws {
        service.setScenarios([
            Scenario.fixture(name: "Movie time").inGroup("living_room").build(),
            Scenario.fixture(name: "Wake up").inGroup("bedroom").build()
        ])
        await viewModel.load()

        viewModel.selectedGroup = .named("bedroom")

        let section = try #require(viewModel.visibleSections.first)
        #expect(viewModel.visibleSections.count == 1)
        #expect(section.scenarios.map(\.name) == ["Wake up"])
    }

    @Test
    func visibleSectionsWhenTheSelectedGroupHasNoScenariosIsEmpty() async {
        service.setScenarios([Scenario.fixture(name: "Movie time").inGroup("living_room").build()])
        await viewModel.load()

        viewModel.selectedGroup = .named("kitchen")

        #expect(viewModel.visibleSections.isEmpty)
    }
}
