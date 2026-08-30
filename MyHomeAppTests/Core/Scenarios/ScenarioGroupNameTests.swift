import Testing
@testable import MyHomeApp

struct ScenarioGroupNameTests {
    // MARK: - label(for:)

    @Test(arguments: [
        ("living_room", "Living Room"),
        ("kitchen", "Kitchen"),
        ("winter_garden", "Winter Garden")
    ])
    func labelHumanisesTheGroupName(group: String, expected: String) {
        #expect(ScenarioGroupName.label(for: group) == expected)
    }

    @Test(arguments: [nil, "", "   "] as [String?])
    func labelForAScenarioWithoutAGroupIsUngrouped(group: String?) {
        #expect(ScenarioGroupName.label(for: group) == "Ungrouped")
    }

    // MARK: - isValid(_:) — mirrors the hub's group name rule

    @Test(arguments: ["living_room", "favourites", "room2", "abc"])
    func namesTheHubAcceptsAreValid(name: String) {
        #expect(ScenarioGroupName.isValid(name))
    }

    @Test(arguments: [
        "ab",                       // shorter than 3
        "living room",              // spaces
        "living-room",              // hyphens
        "живая_комната",            // non-English letters
        "123"                       // digits only
    ])
    func namesTheHubRejectsAreInvalid(name: String) {
        #expect(!ScenarioGroupName.isValid(name))
    }

    @Test
    func namesLongerThanTheHubLimitAreInvalid() {
        #expect(ScenarioGroupName.isValid(String(repeating: "a", count: 40)))
        #expect(!ScenarioGroupName.isValid(String(repeating: "a", count: 41)))
    }
}
