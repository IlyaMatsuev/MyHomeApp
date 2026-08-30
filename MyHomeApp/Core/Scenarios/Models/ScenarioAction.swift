import AnyCodable

struct ScenarioAction: Codable, Hashable {
    let externalId: String
    let set: ScenarioActionSet
}

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
        if !controls.isEmpty {
            try container.encode(controls, forKey: .controls)
        }
        if !measurements.isEmpty {
            try container.encode(measurements, forKey: .measurements)
        }
    }
}
