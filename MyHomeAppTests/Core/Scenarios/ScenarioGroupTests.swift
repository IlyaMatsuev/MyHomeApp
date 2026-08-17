import Foundation
import Testing
@testable import MyHomeApp

struct ScenarioGroupTests {
    // MARK: - label

    @Test(arguments: [
        ("living_room", "Living Room"),
        ("living-room", "Living Room"),
        ("kitchen", "Kitchen"),
        ("winter garden", "Winter Garden"),
    ])
    func labelHumanisesTheRawValue(rawValue: String, expected: String) {
        #expect(ScenarioGroup(rawValue).label == expected)
    }

    @Test(arguments: ["none", ""])
    func labelForAnAbsentGroupIsGeneral(rawValue: String) {
        let group = ScenarioGroup(rawValue)

        #expect(group.isGeneral)
        #expect(group.label == "General")
    }

    // MARK: - ordering

    @Test
    func generalSortsBeforeEveryOtherGroup() {
        let groups = [ScenarioGroup("office"), .general, ScenarioGroup("bedroom")]

        #expect(groups.sorted().map(\.label) == ["General", "Bedroom", "Office"])
    }

    @Test
    func groupsSortByTheirDisplayLabel() {
        let groups = [ScenarioGroup("winter_garden"), ScenarioGroup("bedroom"), ScenarioGroup("living_room")]

        #expect(groups.sorted().map(\.label) == ["Bedroom", "Living Room", "Winter Garden"])
    }

    // MARK: - coding

    @Test
    func groupCodesAsAPlainString() throws {
        struct Wrapper: Codable, Equatable {
            let group: ScenarioGroup
        }

        let data = try JSONEncoder().encode(Wrapper(group: ScenarioGroup("living_room")))
        let decoded = try JSONDecoder().decode(Wrapper.self, from: data)

        #expect(String(data: data, encoding: .utf8) == "{\"group\":\"living_room\"}")
        #expect(decoded.group == ScenarioGroup("living_room"))
    }
}
