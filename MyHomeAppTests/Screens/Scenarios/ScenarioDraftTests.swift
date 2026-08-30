import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

struct ScenarioDraftTests {
    private static func sampleScenario() -> Scenario {
        Scenario.fixture(name: "Warm light on")
            .withDescription("Switches on the warm light in the living room")
            .inGroup("living_room")
            .withCron("8 21 * * *", adjustTo: .sunset)
            .withDeviceCommand(deviceId: "remote-1", value: "up_press")
            .withDeviceControl(deviceId: "plug-1", value: false)
            .withLogic("(1 OR 2) AND 3")
            .withAction(deviceId: "plug-1", value: true)
            .build()
    }

    // MARK: - a brand new draft

    @Test
    func aNewDraftIsActiveAndIncomplete() {
        let draft = ScenarioDraft()

        #expect(draft.active)
        #expect(draft.logicMode == .all)
        #expect(!draft.isValid)
    }

    // MARK: - reading a scenario

    @Test
    func initFromScenarioCopiesTheDetails() {
        let draft = ScenarioDraft(scenario: Self.sampleScenario())

        #expect(draft.name == "Warm light on")
        #expect(draft.description == "Switches on the warm light in the living room")
        #expect(draft.group == "living_room")
        #expect(draft.active)
    }

    @Test
    func initFromScenarioFlattensEverySourceKind() throws {
        let draft = ScenarioDraft(scenario: Self.sampleScenario())

        #expect(draft.sources.count == 3)

        let cron = try #require(draft.sources.first)
        #expect(cron.kind == .cron)
        #expect(cron.cron == "8 21 * * *")
        #expect(cron.adjustTo == .sunset)

        let command = draft.sources[1]
        #expect(command.kind == .device)
        #expect(command.deviceId == "remote-1")
        #expect(command.matchKind == .command)
        #expect(command.matchKey == "action")
        #expect(command.matchText == "up_press")

        let control = draft.sources[2]
        #expect(control.matchKind == .control)
        #expect(control.deviceId == "plug-1")
        #expect(control.matchKey == "on")
        #expect(control.matchValue == false)
    }

    @Test
    func initFromScenarioFlattensTheActions() throws {
        let draft = ScenarioDraft(scenario: Self.sampleScenario())

        let action = try #require(draft.actions.first)
        #expect(draft.actions.count == 1)
        #expect(action.deviceId == "plug-1")
        #expect(action.controlKey == "on")
        #expect(action.value)
    }

    @Test
    func initFromScenarioKeepsAnUnrecognisedExpressionAsCustom() {
        let draft = ScenarioDraft(scenario: Self.sampleScenario())

        #expect(draft.logicMode == .custom)
        #expect(draft.customLogic == "(1 OR 2) AND 3")
    }

    @Test
    func initFromScenarioRecognisesTheCanonicalAndForm() {
        let scenario = Scenario.fixture(name: "Two triggers")
            .withCron("0 8 * * *")
            .withCron("0 20 * * *")
            .withLogic("1 AND 2")
            .build()

        let draft = ScenarioDraft(scenario: scenario)

        #expect(draft.logicMode == .all)
        #expect(draft.customLogic.isEmpty)
    }

    @Test
    func initFromScenarioLeavesTheGroupEmptyWhenTheHubSentNone() {
        let scenario = Scenario.fixture(name: "Nightly").withCron("0 1 * * *").build()

        #expect(ScenarioDraft(scenario: scenario).group.isEmpty)
    }

    @Test
    func initFromScenarioFlattensAMeasurementSource() throws {
        let scenario = Scenario.fixture(name: "Too warm")
            .withDeviceMeasurement(deviceId: "sensor-1", key: "temperature", value: 24)
            .withAction(deviceId: "fan-1", value: true)
            .build()

        let source = try #require(ScenarioDraft(scenario: scenario).sources.first)

        #expect(source.matchKind == .measurement)
        #expect(source.matchKey == "temperature")
        #expect(source.matchText == "24")
    }

    @Test
    func payloadKeepsAMeasurementSetterTheEditorCannotShow() throws {
        let action = ScenarioAction(
            externalId: "thermostat-1",
            set: ScenarioActionSet(controls: ["on": true], measurements: ["target": 21])
        )

        let rebuilt = ScenarioActionDraft(action: action).action

        #expect(rebuilt.set.measurements == ["target": AnyCodable(21)])
        #expect(rebuilt.set.controls == ["on": AnyCodable(true)])
    }

    // MARK: - writing a payload

    @Test
    func payloadRoundTripsTheScenarioItWasBuiltFrom() {
        let scenario = Self.sampleScenario()

        let payload = ScenarioDraft(scenario: scenario).payload

        #expect(payload.name == scenario.name)
        #expect(payload.description == scenario.description)
        #expect(payload.group == scenario.group)
        #expect(payload.active == scenario.active)
        #expect(payload.trigger.sources == scenario.trigger.sources)
        #expect(payload.trigger.logic == scenario.trigger.logic)
        #expect(payload.actions == scenario.actions)
    }

    @Test
    func payloadWritesTheCanonicalExpressionForAllAndAny() {
        var draft = ScenarioDraft()
        draft.name = "Two triggers"
        draft.sources = [
            ScenarioSourceDraft(kind: .cron),
            ScenarioSourceDraft(kind: .device, deviceId: "plug-1")
        ]
        draft.actions = [ScenarioActionDraft(deviceId: "plug-1")]

        #expect(draft.payload.trigger.logic == "1 AND 2")

        draft.logicMode = .any
        #expect(draft.payload.trigger.logic == "1 OR 2")
    }

    @Test
    func payloadTrimsTextAndDropsEmptyOptionals() {
        var draft = ScenarioDraft()
        draft.name = "  Movie time  "
        draft.description = "   "
        draft.group = "   "
        draft.sources = [ScenarioSourceDraft(kind: .cron)]
        draft.actions = [ScenarioActionDraft(deviceId: "plug-1")]

        let payload = draft.payload

        #expect(payload.name == "Movie time")
        #expect(payload.description == nil)
        #expect(payload.group == nil)
    }

    @Test
    func payloadEncodesADeviceCommandSourceAsACommandMatch() throws {
        var draft = ScenarioDraft()
        draft.name = "Remote press"
        draft.sources = [
            ScenarioSourceDraft(
                kind: .device,
                deviceId: "remote-1",
                matchKind: .command,
                matchKey: "action",
                matchText: "up_press"
            )
        ]
        draft.actions = [ScenarioActionDraft(deviceId: "plug-1")]

        let source = try #require(draft.payload.trigger.sources.first)

        #expect(
            source == .device(
                ScenarioDeviceTrigger(
                    externalId: "remote-1",
                    commands: ScenarioValueMatch(are: ["action": AnyCodable("up_press")])
                )
            )
        )
    }

    // MARK: - logic mode switching

    @Test
    func switchingToCustomSeedsTheExpressionFromThePreviousChoice() {
        var draft = ScenarioDraft()
        draft.sources = [
            ScenarioSourceDraft(kind: .cron),
            ScenarioSourceDraft(kind: .device, deviceId: "plug-1")
        ]
        draft.logicMode = .any

        draft.logicMode = .custom

        #expect(draft.customLogic == "1 OR 2")
    }

    @Test
    func switchingToCustomKeepsAnExpressionTheUserAlreadyTyped() {
        var draft = ScenarioDraft(scenario: Self.sampleScenario())

        draft.logicMode = .all
        draft.logicMode = .custom

        #expect(draft.customLogic == "(1 OR 2) AND 3")
    }
}
