/// Device configs matching the ones the hub ships in `configs/devices/*.yaml`.
///
/// Used by `MockDeviceService` so previews and the mocked app exercise the same dynamic layout the
/// real hub drives.
enum MockDeviceConfigs {
    static let onControl = DeviceConfigItem(
        label: "On",
        name: "on",
        type: .boolean,
        description: "Switch on/off state"
    )

    static let tuyaLED = DeviceConfig(
        commands: nil,
        controls: [
            onControl,
            DeviceConfigItem(
                label: "Brightness",
                name: "brightness",
                type: .number,
                description: "Brightness level 1-100",
                constraints: DeviceConfigItemConstraints(min: 1, max: 100, integer: true)
            ),
            DeviceConfigItem(
                label: "Color",
                name: "color",
                type: .string,
                constraints: DeviceConfigItemConstraints(format: .hexColor)
            )
        ],
        measurements: nil
    )

    static let shellyLED = DeviceConfig(
        commands: nil,
        controls: [
            onControl,
            DeviceConfigItem(
                label: "Mode",
                name: "mode",
                type: .enumeration,
                description: "Defines whether the light color or the color temperature is applied",
                values: [
                    DeviceConfigItemOption(label: "Color", name: "rgb", path: nil),
                    DeviceConfigItemOption(label: "White", name: "cct", path: nil)
                ]
            ),
            DeviceConfigItem(
                label: "Brightness",
                name: "brightness",
                type: .number,
                description: "Brightness level 0-100",
                constraints: DeviceConfigItemConstraints(min: 0, max: 100, integer: true)
            ),
            DeviceConfigItem(
                label: "Color",
                name: "color",
                type: .string,
                constraints: DeviceConfigItemConstraints(format: .hexColor)
            ),
            DeviceConfigItem(
                label: "Color temperature",
                name: "temperature",
                type: .number,
                description: "White light color temperature in kelvins (2700-6500)",
                constraints: DeviceConfigItemConstraints(min: 2700, max: 6500, integer: true)
            ),
            DeviceConfigItem(
                label: "Transition duration",
                name: "transitionDuration",
                type: .number,
                description: "Duration of the fade between the light states in seconds (0.5-10800)",
                constraints: DeviceConfigItemConstraints(min: 0.5, max: 10800)
            )
        ],
        measurements: [powerMeasurement]
    )

    static let shellyPlug = DeviceConfig(
        commands: nil,
        controls: [onControl],
        measurements: [
            DeviceConfigItem(
                label: "Voltage",
                name: "voltage",
                type: .number,
                description: "The currently consumed voltage (volts) while the device is on"
            ),
            DeviceConfigItem(
                label: "Current",
                name: "current",
                type: .number,
                description: "The currently consumed current (amperes) while the device is on"
            ),
            powerMeasurement
        ]
    )

    static let googleSpeaker = DeviceConfig(
        commands: [
            DeviceConfigItem(
                label: "Text-to-speech",
                name: "text",
                type: .string,
                description: "The text to be repeated by the Google assistant text-to-speech",
                constraints: DeviceConfigItemConstraints(minLength: 1)
            )
        ],
        controls: nil,
        measurements: nil
    )

    static let philipsRemote = DeviceConfig(
        commands: [
            DeviceConfigItem(
                label: "On",
                name: "on",
                type: .boolean,
                description: "Switch on/off state",
                path: "action",
                values: [
                    DeviceConfigItemOption(label: "On", name: "true", path: "on_press"),
                    DeviceConfigItemOption(label: "Off", name: "false", path: "off_press")
                ]
            ),
            DeviceConfigItem(
                label: "Brightness Up/Down",
                name: "brightness",
                type: .boolean,
                description: "Change brightness one step up (true) or down (false)",
                path: "action",
                values: [
                    DeviceConfigItemOption(label: "Up", name: "true", path: "up_press"),
                    DeviceConfigItemOption(label: "Down", name: "false", path: "down_press")
                ]
            )
        ],
        controls: nil,
        measurements: [
            DeviceConfigItem(
                label: "Battery level",
                name: "battery",
                type: .number,
                description: "The battery level 0-100"
            ),
            DeviceConfigItem(
                label: "Connection quality",
                name: "linkquality",
                type: .number,
                description: "The quality of this device connection with the hub"
            )
        ]
    )

    private static let powerMeasurement = DeviceConfigItem(
        label: "Power",
        name: "power",
        type: .number,
        description: "The currently consumed power (watts) while the device is on",
        path: "apower"
    )
}
