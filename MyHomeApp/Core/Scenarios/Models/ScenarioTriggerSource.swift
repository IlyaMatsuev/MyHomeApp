import AnyCodable

/// One entry of `trigger.sources`.
///
/// The wire format is not uniform: a `cron` source carries its payload flat next to `type`,
/// while a `device` source nests it under a `device` key — hence the hand-written `Codable`.
enum ScenarioTriggerSource: Codable, Hashable {
    case cron(ScenarioCronTrigger)
    case device(ScenarioDeviceTrigger)

    enum Kind: String, Codable, Hashable, CaseIterable, Identifiable {
        case cron
        case device

        var id: String { rawValue }

        var label: String {
            switch self {
            case .cron: return "On a schedule"
            case .device: return "When a device…"
            }
        }

        var iconSystemName: String {
            switch self {
            case .cron: return "clock"
            case .device: return "dot.radiowaves.left.and.right"
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case cron
        case adjustTo
        case device
    }

    var kind: Kind {
        switch self {
        case .cron: return .cron
        case .device: return .device
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .type) {
        case .cron:
            self = .cron(
                ScenarioCronTrigger(
                    cron: try container.decode(String.self, forKey: .cron),
                    adjustTo: try container.decodeIfPresent(ScenarioSolarAdjustment.self, forKey: .adjustTo)
                )
            )

        case .device:
            self = .device(try container.decode(ScenarioDeviceTrigger.self, forKey: .device))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .type)
        switch self {
        case .cron(let trigger):
            try container.encode(trigger.cron, forKey: .cron)
            try container.encodeIfPresent(trigger.adjustTo, forKey: .adjustTo)

        case .device(let trigger):
            try container.encode(trigger, forKey: .device)
        }
    }
}

struct ScenarioCronTrigger: Hashable, Sendable {
    let cron: String
    let adjustTo: ScenarioSolarAdjustment?

    init(cron: String, adjustTo: ScenarioSolarAdjustment? = nil) {
        self.cron = cron
        self.adjustTo = adjustTo
    }
}

/// A device the scenario watches. The hub requires at least one of the three sections to be non-empty.
struct ScenarioDeviceTrigger: Codable, Hashable {
    let externalId: String
    let commands: ScenarioValueMatch?
    let controls: ScenarioValueMatch?
    let measurements: ScenarioValueMatch?

    init(
        externalId: String,
        commands: ScenarioValueMatch? = nil,
        controls: ScenarioValueMatch? = nil,
        measurements: ScenarioValueMatch? = nil
    ) {
        self.externalId = externalId
        self.commands = commands
        self.controls = controls
        self.measurements = measurements
    }
}

/// The `{ "are": { … } }` matcher the hub uses for every device condition section.
struct ScenarioValueMatch: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case are
    }

    let are: [String: AnyCodable]

    init(are: [String: AnyCodable]) {
        self.are = are
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        are = try container.decodeIfPresent([String: AnyCodable].self, forKey: .are) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(are, forKey: .are)
    }
}
