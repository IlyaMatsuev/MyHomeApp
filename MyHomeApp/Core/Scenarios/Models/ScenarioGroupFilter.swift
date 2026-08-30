enum ScenarioGroupFilter: Hashable {
    case all
    case ungrouped
    case named(String)

    init(group: String?) {
        self = group.map(Self.named) ?? .ungrouped
    }
}

extension ScenarioGroupFilter {
    var label: String {
        switch self {
        case .all: return "All"
        case .ungrouped: return ScenarioGroupName.ungroupedLabel
        case .named(let group): return ScenarioGroupName.label(for: group)
        }
    }

    func matches(group: String?) -> Bool {
        switch self {
        case .all: return true
        case .ungrouped: return group == nil
        case .named(let name): return group == name
        }
    }
}
