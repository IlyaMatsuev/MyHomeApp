/// Bounds the hub enforces on a command/control/measurement value.
///
/// Mirrors `DeviceConfigItemConstraints` in the hub. Only the constraints that apply to the item's
/// type are ever sent: `min`/`max`/`integer` for numbers, the rest for strings.
struct DeviceConfigItemConstraints: Codable, Hashable {
    let min: Double?
    let max: Double?
    let integer: Bool?
    let minLength: Int?
    let maxLength: Int?
    let pattern: String?
    let format: DeviceConfigItemFormat?

    init(
        min: Double? = nil,
        max: Double? = nil,
        integer: Bool? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil,
        format: DeviceConfigItemFormat? = nil
    ) {
        self.min = min
        self.max = max
        self.integer = integer
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.format = format
    }
}

extension DeviceConfigItemConstraints {
    /// The closed range a slider can span, or `nil` when the hub left one end open.
    var numericRange: ClosedRange<Double>? {
        guard let min, let max, min < max else { return nil }
        return min...max
    }

    /// Slider step that keeps an integer-only control on whole numbers.
    var numericStep: Double {
        integer == true ? 1 : 0.1
    }
}
