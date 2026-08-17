/// Shifts a cron trigger to a solar event instead of a fixed wall-clock time.
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
