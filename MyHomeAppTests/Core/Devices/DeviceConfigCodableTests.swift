import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

struct DeviceConfigCodableTests {
    // MARK: - Decoding the hub's shape

    @Test
    func decodesEveryFieldOfAConfigItem() throws {
        let json = """
        {
            "controls": [
                {
                    "label": "Brightness",
                    "name": "brightness",
                    "type": "number",
                    "description": "Brightness level 1-100",
                    "path": "20",
                    "required": true,
                    "default": 50,
                    "constraints": { "min": 1, "max": 100, "integer": true }
                }
            ]
        }
        """

        let config = try JSONDecoder().decode(DeviceConfig.self, from: Data(json.utf8))

        let item = try #require(config.controlItems.first)
        #expect(item.label == "Brightness")
        #expect(item.name == "brightness")
        #expect(item.type == .number)
        #expect(item.description == "Brightness level 1-100")
        #expect(item.path == "20")
        #expect(item.required == true)
        #expect(item.defaultValue == AnyCodable(50))
        #expect(item.constraints?.min == 1)
        #expect(item.constraints?.max == 100)
        #expect(item.constraints?.integer == true)
    }

    @Test
    func decodesEnumValuesWithTheirDeviceSideMapping() throws {
        let json = """
        {
            "commands": [
                {
                    "label": "On",
                    "name": "on",
                    "type": "boolean",
                    "path": "action",
                    "values": [
                        { "label": "On", "name": "true", "path": "on_press" },
                        { "label": "Off", "name": "false", "path": "off_press" }
                    ]
                }
            ]
        }
        """

        let config = try JSONDecoder().decode(DeviceConfig.self, from: Data(json.utf8))

        let item = try #require(config.commandItems.first)
        #expect(item.options.map(\.name) == ["true", "false"])
        #expect(item.options.map(\.path) == ["on_press", "off_press"])
        #expect(item.optionLabel(forName: "true") == "On")
    }

    @Test
    func decodesAStringFormatConstraint() throws {
        let json = """
        { "controls": [{ "label": "Color", "name": "color", "type": "string",
          "constraints": { "format": "hex-color" } }] }
        """

        let config = try JSONDecoder().decode(DeviceConfig.self, from: Data(json.utf8))

        #expect(config.controlItems.first?.constraints?.format == .hexColor)
    }

    @Test
    func decodesMissingSectionsAsEmpty() throws {
        let config = try JSONDecoder().decode(DeviceConfig.self, from: Data("{}".utf8))

        #expect(config.commandItems.isEmpty)
        #expect(config.controlItems.isEmpty)
        #expect(config.measurementItems.isEmpty)
    }

    @Test
    func decodesExplicitNullFieldsAsAbsent() throws {
        let json = """
        { "controls": [{ "label": "On", "name": "on", "type": "boolean",
          "description": null, "path": null, "required": null, "constraints": null,
          "values": null, "default": null }] }
        """

        let config = try JSONDecoder().decode(DeviceConfig.self, from: Data(json.utf8))

        let item = try #require(config.controlItems.first)
        #expect(item.description == nil)
        #expect(item.constraints == nil)
        #expect(item.options.isEmpty)
        #expect(item.defaultValue == nil)
    }

    // MARK: - Unknown vocabulary

    @Test
    func keepsAnUnknownItemTypeInsteadOfFailingTheWholeConfig() throws {
        let json = """
        { "controls": [{ "label": "Schedule", "name": "schedule", "type": "matrix" }] }
        """

        let config = try JSONDecoder().decode(DeviceConfig.self, from: Data(json.utf8))

        let item = try #require(config.controlItems.first)
        #expect(item.type == .unsupported("matrix"))
        #expect(item.isEditable == false)
    }

    @Test
    func keepsAnUnknownStringFormatInsteadOfFailingTheWholeConfig() throws {
        let json = """
        { "controls": [{ "label": "Slug", "name": "slug", "type": "string",
          "constraints": { "format": "uuid" } }] }
        """

        let config = try JSONDecoder().decode(DeviceConfig.self, from: Data(json.utf8))

        #expect(config.controlItems.first?.constraints?.format == .unsupported("uuid"))
    }

    // MARK: - Round trip

    @Test
    func roundTripsThroughJSON() throws {
        let original = MockDeviceConfigs.shellyLED

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DeviceConfig.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Item types

    @Test(arguments: [
        ("boolean", DeviceConfigItemType.boolean),
        ("number", .number),
        ("string", .string),
        ("enum", .enumeration),
        ("object", .object)
    ])
    func mapsEveryWireItemType(wireValue: String, expected: DeviceConfigItemType) {
        #expect(DeviceConfigItemType(wireValue: wireValue) == expected)
        #expect(expected.wireValue == wireValue)
    }

    @Test
    func onlyScalarItemTypesAreEditable() {
        #expect(DeviceConfigItemType.boolean.isEditable)
        #expect(DeviceConfigItemType.number.isEditable)
        #expect(DeviceConfigItemType.string.isEditable)
        #expect(DeviceConfigItemType.enumeration.isEditable)
        #expect(DeviceConfigItemType.object.isEditable == false)
    }

    // MARK: - Constraints

    @Test
    func numericRangeNeedsBothEnds() {
        #expect(DeviceConfigItemConstraints(min: 1, max: 100).numericRange == 1...100)
        #expect(DeviceConfigItemConstraints(min: 1).numericRange == nil)
        #expect(DeviceConfigItemConstraints(max: 100).numericRange == nil)
    }

    @Test
    func numericRangeIgnoresAnInvertedRange() {
        #expect(DeviceConfigItemConstraints(min: 100, max: 1).numericRange == nil)
    }

    @Test
    func numericStepIsWholeForIntegerItems() {
        #expect(DeviceConfigItemConstraints(integer: true).numericStep == 1)
        #expect(DeviceConfigItemConstraints(integer: false).numericStep == 0.1)
    }
}
