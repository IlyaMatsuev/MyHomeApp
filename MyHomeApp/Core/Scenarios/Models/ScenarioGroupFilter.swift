enum ScenarioGroupFilter: Hashable {
    case all
    case specific(ScenarioGroup)
}

extension ScenarioGroupFilter {
    var label: String {
        switch self {
        case .all: return "All"
        case .specific(let group): return group.label
        }
    }
}
