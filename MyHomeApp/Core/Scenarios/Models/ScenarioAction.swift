import AnyCodable

/// One entry of the scenario's `actions` array — what to change when the trigger fires.
struct ScenarioAction: Codable, Hashable {
    let externalId: String
    let set: ScenarioActionSet
}

/// The values written to the device. The hub requires at least one of the two sections to be non-empty.
struct ScenarioActionSet: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case controls
        case measurements
    }

    let controls: [String: AnyCodable]
    let measurements: [String: AnyCodable]

    init(controls: [String: AnyCodable] = [:], measurements: [String: AnyCodable] = [:]) {
        self.controls = controls
        self.measurements = measurements
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        controls = try container.decodeIfPresent([String: AnyCodable].self, forKey: .controls) ?? [:]
        measurements = try container.decodeIfPresent([String: AnyCodable].self, forKey: .measurements) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // The hub rejects an empty section object, so only the populated ones go on the wire.
        if !controls.isEmpty {
            try container.encode(controls, forKey: .controls)
        }
        if !measurements.isEmpty {
            try container.encode(measurements, forKey: .measurements)
        }
    }
}
