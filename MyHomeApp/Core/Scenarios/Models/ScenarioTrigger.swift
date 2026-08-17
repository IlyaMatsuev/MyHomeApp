import Foundation

struct ScenarioTrigger: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case sources
        case logic
    }

    let sources: [ScenarioTriggerSource]

    /// Raw hub expression combining the sources by their 1-based position, e.g. `"(1 OR 2) AND 3"`.
    /// Use `ScenarioTriggerLogic` to work with it — see FEATURE_PLAN.md for why positions are a footgun.
    let logic: String?

    init(sources: [ScenarioTriggerSource], logic: String? = nil) {
        self.sources = sources
        self.logic = logic
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sources = try container.decodeIfPresent([ScenarioTriggerSource].self, forKey: .sources) ?? []
        logic = try container.decodeIfPresent(String.self, forKey: .logic)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sources, forKey: .sources)
        try container.encodeIfPresent(logic, forKey: .logic)
    }
}
