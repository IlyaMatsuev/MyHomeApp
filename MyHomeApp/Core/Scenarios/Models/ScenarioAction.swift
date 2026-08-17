import Foundation
import AnyCodable

/// One entry of the scenario's `devices` array — what to change when the trigger fires.
struct ScenarioAction: Codable, Hashable {
    let externalId: String
    let set: ScenarioActionSet

    init(externalId: String, set: ScenarioActionSet) {
        self.externalId = externalId
        self.set = set
    }
}

struct ScenarioActionSet: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case controls
    }

    let controls: [String: AnyCodable]

    init(controls: [String: AnyCodable]) {
        self.controls = controls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        controls = try container.decodeIfPresent([String: AnyCodable].self, forKey: .controls) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(controls, forKey: .controls)
    }
}
