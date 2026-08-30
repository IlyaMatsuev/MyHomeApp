import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

struct ScenarioCodableTests {
    private static let sampleJSON = """
    {
        "name": "Warm light on",
        "description": "Switches on the warm light in the living room",
        "trigger": {
            "sources": [
                {
                    "type": "cron",
                    "cron": "8 21 * * *",
                    "adjustTo": "sunset"
                },
                {
                    "type": "device",
                    "device": {
                        "externalId": "7662737f-400b-48c2-9719-45a4a14bad9c",
                        "commands": {
                            "are": {
                                "action": "up_press"
                            }
                        }
                    }
                },
                {
                    "type": "device",
                    "device": {
                        "externalId": "5f9ffdce-bf7b-4fdf-9a3e-7c62edf77ca0",
                        "controls": {
                            "are": {
                                "on": false
                            }
                        }
                    }
                }
            ],
            "logic": "(1 OR 2) AND 3"
        },
        "actions": [
            {
                "externalId": "5f9ffdce-bf7b-4fdf-9a3e-7c62edf77ca0",
                "set": {
                    "controls": {
                        "on": true
                    }
                }
            }
        ],
        "externalId": "d3ccf155-3ed5-459c-aec2-f37f6402f1a1",
        "active": true,
        "createdAt": "2025-08-30T16:04:38.229Z",
        "updatedAt": "2026-08-15T10:52:37.396Z",
        "group": "living_room"
    }
    """

    private static func decodeSample() throws -> Scenario {
        try JSONDecoder.hubAPI.decode(Scenario.self, from: Data(sampleJSON.utf8))
    }

    // MARK: - decoding the hub payload

    @Test
    func decodeReadsScalarFields() throws {
        let scenario = try Self.decodeSample()

        #expect(scenario.externalId == "d3ccf155-3ed5-459c-aec2-f37f6402f1a1")
        #expect(scenario.id == scenario.externalId)
        #expect(scenario.name == "Warm light on")
        #expect(scenario.description == "Switches on the warm light in the living room")
        #expect(scenario.active == true)
        #expect(scenario.group == "living_room")
        #expect(scenario.repeatTimes == nil, "An omitted repeatTimes means the scenario repeats forever")
    }

    @Test
    func decodeReadsTimestampsAsISO8601WithFractionalSeconds() throws {
        let scenario = try Self.decodeSample()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = try #require(formatter.date(from: "2025-08-30T16:04:38.229Z"))
        let updatedAt = try #require(formatter.date(from: "2026-08-15T10:52:37.396Z"))

        #expect(scenario.createdAt == createdAt)
        #expect(scenario.updatedAt == updatedAt)
    }

    @Test
    func decodeReadsCronSourceFromFlatFields() throws {
        let scenario = try Self.decodeSample()

        let source = try #require(scenario.trigger.sources.first)
        #expect(source == .cron(ScenarioCronTrigger(cron: "8 21 * * *", adjustTo: .sunset)))
    }

    @Test
    func decodeReadsDeviceSourcesFromNestedDeviceKey() throws {
        let scenario = try Self.decodeSample()

        #expect(scenario.trigger.sources.count == 3)
        #expect(
            scenario.trigger.sources[1] == .device(
                ScenarioDeviceTrigger(
                    externalId: "7662737f-400b-48c2-9719-45a4a14bad9c",
                    commands: ScenarioValueMatch(are: ["action": AnyCodable("up_press")])
                )
            )
        )
        #expect(
            scenario.trigger.sources[2] == .device(
                ScenarioDeviceTrigger(
                    externalId: "5f9ffdce-bf7b-4fdf-9a3e-7c62edf77ca0",
                    controls: ScenarioValueMatch(are: ["on": AnyCodable(false)])
                )
            )
        )
    }

    @Test
    func decodeKeepsTheRawLogicExpression() throws {
        let scenario = try Self.decodeSample()

        #expect(scenario.trigger.logic == "(1 OR 2) AND 3")
    }

    @Test
    func decodeMapsTheDevicesArrayOntoActions() throws {
        let scenario = try Self.decodeSample()

        let action = try #require(scenario.actions.first)
        #expect(scenario.actions.count == 1)
        #expect(action.externalId == "5f9ffdce-bf7b-4fdf-9a3e-7c62edf77ca0")
        #expect(action.set.controls == ["on": AnyCodable(true)])
    }

    // MARK: - decoding tolerances

    @Test
    func decodeWithoutTheOptionalFieldsSucceeds() throws {
        let json = """
        {
            "externalId": "scenario-1",
            "name": "Bare",
            "active": true,
            "trigger": { "sources": [{ "type": "cron", "cron": "0 8 * * *" }], "logic": "1" },
            "actions": [{ "externalId": "device-1", "set": { "controls": { "on": true } } }],
            "createdAt": "2025-08-30T16:04:38.229Z",
            "updatedAt": "2025-08-30T16:04:38.229Z"
        }
        """

        let scenario = try JSONDecoder.hubAPI.decode(Scenario.self, from: Data(json.utf8))

        #expect(scenario.description == nil)
        #expect(scenario.group == nil, "No group at all — the hub has no \"none\" group")
        #expect(scenario.repeatTimes == nil)
    }

    @Test
    func decodeReadsRepeatTimes() throws {
        let json = Self.sampleJSON
            .replacingOccurrences(of: "\"active\": true", with: "\"active\": true, \"repeatTimes\": 3")

        let scenario = try JSONDecoder.hubAPI.decode(Scenario.self, from: Data(json.utf8))

        #expect(scenario.repeatTimes == 3)
    }

    @Test
    func decodeAcceptsAGroupTheAppHasNeverSeen() throws {
        let json = Self.sampleJSON.replacingOccurrences(of: "\"living_room\"", with: "\"winter_garden\"")

        let scenario = try JSONDecoder.hubAPI.decode(Scenario.self, from: Data(json.utf8))

        #expect(scenario.group == "winter_garden")
        #expect(ScenarioGroupName.label(for: scenario.group) == "Winter Garden")
    }

    // MARK: - the sections the editor cannot express

    @Test
    func decodeReadsAMeasurementTriggerSource() throws {
        let json = """
        {
            "type": "device",
            "device": {
                "externalId": "device-1",
                "measurements": { "are": { "temperature": 21 } }
            }
        }
        """

        let source = try JSONDecoder.hubAPI.decode(ScenarioTriggerSource.self, from: Data(json.utf8))

        #expect(
            source == .device(
                ScenarioDeviceTrigger(
                    externalId: "device-1",
                    measurements: ScenarioValueMatch(are: ["temperature": AnyCodable(21)])
                )
            )
        )
    }

    @Test
    func actionSetRoundTripsBothSections() throws {
        let json = """
        {
            "externalId": "device-1",
            "set": { "controls": { "on": true }, "measurements": { "target": 21 } }
        }
        """

        let action = try JSONDecoder.hubAPI.decode(ScenarioAction.self, from: Data(json.utf8))
        #expect(action.set.controls == ["on": AnyCodable(true)])
        #expect(action.set.measurements == ["target": AnyCodable(21)])

        let encoded = try JSONSerialization.jsonObject(with: try JSONEncoder().encode(action))
        let object = try #require(encoded as? [String: Any])
        let set = try #require(object["set"] as? [String: Any])
        #expect(set["controls"] != nil)
        #expect(set["measurements"] != nil)
    }

    @Test
    func encodeOmitsAnEmptyActionSection() throws {
        let action = ScenarioAction(externalId: "device-1", set: ScenarioActionSet(controls: ["on": true]))

        let encoded = try JSONSerialization.jsonObject(with: try JSONEncoder().encode(action))
        let object = try #require(encoded as? [String: Any])
        let set = try #require(object["set"] as? [String: Any])

        #expect(set["measurements"] == nil, "The hub rejects an empty section object")
    }

    @Test
    func decodeRejectsAnUnknownTriggerSourceType() {
        let json = Self.sampleJSON.replacingOccurrences(of: "\"type\": \"cron\"", with: "\"type\": \"webhook\"")

        #expect(throws: DecodingError.self) {
            try JSONDecoder.hubAPI.decode(Scenario.self, from: Data(json.utf8))
        }
    }

    // MARK: - encoding

    @Test
    func encodeRestoresTheHubSourceShapes() throws {
        let scenario = try Self.decodeSample()

        let data = try JSONEncoder().encode(scenario.trigger)
        let object = try JSONSerialization.jsonObject(with: data)
        let json = try #require(object as? [String: Any])
        let sources = try #require(json["sources"] as? [[String: Any]])

        #expect(sources[0]["type"] as? String == "cron")
        #expect(sources[0]["cron"] as? String == "8 21 * * *")
        #expect(sources[0]["adjustTo"] as? String == "sunset")
        #expect(sources[1]["type"] as? String == "device")
        #expect(sources[1]["device"] != nil, "A device source nests its payload under \"device\"")
        #expect(sources[1]["externalId"] == nil)
    }

    @Test
    func encodeOmitsAdjustToWhenTheCronIsNotSolar() throws {
        let source = ScenarioTriggerSource.cron(ScenarioCronTrigger(cron: "0 8 * * *"))

        let data = try JSONEncoder().encode(source)
        let object = try JSONSerialization.jsonObject(with: data)
        let json = try #require(object as? [String: Any])

        #expect(json["adjustTo"] == nil)
    }

    @Test
    func scenarioRoundTripsThroughJSON() throws {
        let original = Scenario.fixture(name: "Warm light on")
            .inGroup("living_room")
            .withDescription("Switches on the warm light")
            .withCron("8 21 * * *", adjustTo: .sunset)
            .withDeviceControl(deviceId: "device-1", value: false)
            .withLogic("1 AND 2")
            .withAction(deviceId: "device-1", value: true)
            .build()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Scenario.self, from: data)

        #expect(decoded == original)
    }
}
