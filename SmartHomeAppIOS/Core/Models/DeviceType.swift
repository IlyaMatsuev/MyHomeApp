
enum DeviceType: String, Codable, Hashable, CaseIterable {
    case speaker
    case plug
    case `switch`
    case led
    case fans
    case motionSensor = "motion-sensor"
    case remote

    var label: String { metadata.label }
    var emoji: String { metadata.emoji }
}

extension DeviceType {
    private var metadata: (label: String, emoji: String) {
        switch self {
        case .speaker: return ("Speaker", "🔊")
        case .plug: return ("Plug", "🔌")
        case .switch: return ("Switch", "💡")
        case .led: return ("LED", "💡")
        case .fans: return ("Fans", "🪭")
        case .motionSensor: return ("Motion Sensor", "〰️")
        case .remote: return ("Remote", "🖱️")
        }
    }
}
