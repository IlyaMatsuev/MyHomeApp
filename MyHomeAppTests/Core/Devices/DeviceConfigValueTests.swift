import Foundation
import AnyCodable
import Testing
@testable import MyHomeApp

struct DeviceConfigValueTests {
    private let brightness = DeviceConfigItem(
        label: "Brightness",
        name: "brightness",
        type: .number,
        constraints: DeviceConfigItemConstraints(min: 1, max: 100, integer: true)
    )
    private let color = DeviceConfigItem(
        label: "Color",
        name: "color",
        type: .string,
        constraints: DeviceConfigItemConstraints(format: .hexColor)
    )
    private let mode = DeviceConfigItem(
        label: "Mode",
        name: "mode",
        type: .enumeration,
        values: [
            DeviceConfigItemOption(label: "Color", name: "rgb", path: nil),
            DeviceConfigItemOption(label: "White", name: "cct", path: nil)
        ]
    )

    // MARK: - Reading

    @Test
    func numberReadsBothIntAndDoublePayloads() {
        #expect(DeviceConfigValue.number(AnyCodable(42)) == 42)
        #expect(DeviceConfigValue.number(AnyCodable(1.5)) == 1.5)
        #expect(DeviceConfigValue.number(AnyCodable("nope")) == nil)
    }

    @Test
    func boolAndStringOnlyReadTheirOwnType() {
        #expect(DeviceConfigValue.bool(AnyCodable(true)) == true)
        #expect(DeviceConfigValue.bool(AnyCodable(1)) == nil)
        #expect(DeviceConfigValue.string(AnyCodable("cct")) == "cct")
        #expect(DeviceConfigValue.string(AnyCodable(1)) == nil)
    }

    // MARK: - Formatting

    @Test
    func formatsABooleanAsOnOrOff() {
        let item = MockDeviceConfigs.onControl
        #expect(DeviceConfigValue.text(of: AnyCodable(true), for: item) == "On")
        #expect(DeviceConfigValue.text(of: AnyCodable(false), for: item) == "Off")
    }

    @Test
    func formatsAnIntegerNumberWithoutDecimals() {
        #expect(DeviceConfigValue.text(of: AnyCodable(75.0), for: brightness) == "75")
    }

    @Test
    func formatsAFractionalNumberToAtMostTwoDecimals() {
        let item = DeviceConfigItem(label: "Current", name: "current", type: .number)
        #expect(DeviceConfigValue.text(of: AnyCodable(0.126), for: item) == "0.13")
    }

    @Test
    func formatsAFractionalNumberWithoutTrailingZeros() {
        let item = DeviceConfigItem(label: "Power", name: "power", type: .number)
        #expect(DeviceConfigValue.text(of: AnyCodable(27.5), for: item) == "27.5")
    }

    @Test
    func formatsAnEnumUsingItsLabel() {
        #expect(DeviceConfigValue.text(of: AnyCodable("cct"), for: mode) == "White")
    }

    @Test
    func formatsAnEnumValueTheConfigDoesNotListAsItsRawName() {
        #expect(DeviceConfigValue.text(of: AnyCodable("hsv"), for: mode) == "hsv")
    }

    @Test
    func formatsAMissingValueAsADash() {
        #expect(DeviceConfigValue.text(of: nil, for: brightness) == "—")
    }

    // MARK: - Validation — numbers

    @Test
    func acceptsANumberInsideItsBounds() {
        #expect(DeviceConfigValue.error(for: brightness, value: AnyCodable(50)) == nil)
    }

    @Test
    func rejectsANumberBelowMin() {
        let message = DeviceConfigValue.error(for: brightness, value: AnyCodable(0))
        #expect(message == "Brightness must not be less than 1.")
    }

    @Test
    func rejectsANumberAboveMax() {
        let message = DeviceConfigValue.error(for: brightness, value: AnyCodable(101))
        #expect(message == "Brightness must not be greater than 100.")
    }

    @Test
    func rejectsAFractionalValueForAnIntegerItem() {
        let message = DeviceConfigValue.error(for: brightness, value: AnyCodable(50.5))
        #expect(message == "Brightness must be a whole number.")
    }

    @Test
    func rejectsTextTypedIntoANumberItem() {
        let message = DeviceConfigValue.error(for: brightness, value: AnyCodable("abc"))
        #expect(message == "Brightness must be a number.")
    }

    // MARK: - Validation — strings

    @Test
    func acceptsAHexColour() {
        #expect(DeviceConfigValue.error(for: color, value: AnyCodable("#B7D4FF")) == nil)
        #expect(DeviceConfigValue.error(for: color, value: AnyCodable("B7D4FF")) == nil)
    }

    @Test
    func rejectsSomethingThatIsNotAHexColour() {
        let message = DeviceConfigValue.error(for: color, value: AnyCodable("cornflower"))
        #expect(message == "Color must be a valid hex-color value.")
    }

    @Test
    func rejectsAStringShorterThanMinLength() {
        let item = DeviceConfigItem(
            label: "Text-to-speech",
            name: "text",
            type: .string,
            constraints: DeviceConfigItemConstraints(minLength: 1)
        )
        let message = DeviceConfigValue.error(for: item, value: AnyCodable(""))
        #expect(message == "Text-to-speech must be at least 1 characters.")
        #expect(DeviceConfigValue.error(for: item, value: AnyCodable("Hi")) == nil)
    }

    @Test
    func rejectsAStringLongerThanMaxLength() {
        let item = DeviceConfigItem(
            label: "Note",
            name: "note",
            type: .string,
            constraints: DeviceConfigItemConstraints(maxLength: 3)
        )
        let message = DeviceConfigValue.error(for: item, value: AnyCodable("abcd"))
        #expect(message == "Note must be at most 3 characters.")
    }

    // MARK: - Validation — enums

    @Test
    func acceptsOnlyTheValuesTheConfigLists() {
        #expect(DeviceConfigValue.error(for: mode, value: AnyCodable("rgb")) == nil)
        #expect(DeviceConfigValue.error(for: mode, value: AnyCodable("hsv")) == "Mode must be one of: Color, White.")
    }

    // MARK: - Validation — empty and unsupported

    @Test
    func treatsAMissingValueAsValid() {
        #expect(DeviceConfigValue.error(for: brightness, value: nil) == nil)
    }

    @Test
    func leavesUnsupportedShapesToTheHub() {
        let item = DeviceConfigItem(label: "Speed levels", name: "speedLevels", type: .object)
        #expect(DeviceConfigValue.error(for: item, value: AnyCodable("anything")) == nil)
    }

    // MARK: - Fallback values

    @Test
    func fallbackValuePrefersTheConfiguredDefault() {
        let item = DeviceConfigItem(
            label: "Brightness",
            name: "brightness",
            type: .number,
            defaultValue: AnyCodable(30)
        )
        #expect(item.fallbackValue == AnyCodable(30))
    }

    @Test
    func fallbackValueOfANumberStartsAtItsMinimum() {
        #expect(DeviceConfigValue.number(brightness.fallbackValue) == 1)
    }

    @Test
    func fallbackValueOfAnEnumIsItsFirstOption() {
        #expect(DeviceConfigValue.string(mode.fallbackValue) == "rgb")
    }

    @Test
    func fallbackValueOfABooleanIsOff() {
        #expect(DeviceConfigValue.bool(MockDeviceConfigs.onControl.fallbackValue) == false)
    }
}
