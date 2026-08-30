enum ScenarioSolarAdjustment: String, Codable, Hashable, CaseIterable, Identifiable {
    case sunrise
    case sunset

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunrise: return "Sunrise"
        case .sunset: return "Sunset"
        }
    }
}
