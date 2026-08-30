import Foundation
import AnyCodable

/// Editor-side representation of one `ScenarioTriggerSource`.
///
/// The wire model is an enum with associated values, which SwiftUI cannot bind into. The draft is
/// therefore flat: every field for every kind lives side by side and `kind` decides which ones count.
struct ScenarioSourceDraft: Identifiable, Hashable {
    /// Which of the device's condition sections is being matched — the hub's `commands`,
    /// `controls` or `measurements`, each shaped as `{ "are": { key: value } }`.
    enum MatchKind: String, Hashable, CaseIterable, Identifiable {
        case command
        case control
        case measurement

        var id: String { rawValue }

        var label: String {
            switch self {
            case .command: return "Command"
            case .control: return "Control"
            case .measurement: return "Measurement"
            }
        }
    }

    static let defaultCron = "0 8 * * *"
    static let defaultCommandKey = "action"
    static let defaultControlKey = "on"

    let draftId = UUID()

    var id: UUID { draftId }

    var kind: ScenarioTriggerSource.Kind

    var cron: String
    var adjustTo: ScenarioSolarAdjustment? {
        didSet {
            guard adjustTo != nil, !Self.isCronShaped(cron) else { return }
            cron = Self.defaultCron
        }
    }

    var deviceId: String
    var matchKind: MatchKind
    var matchKey: String
    /// The matched value for a `command` or a `measurement`; a control uses `matchValue` instead.
    var matchText: String
    var matchValue: Bool

    var isValid: Bool {
        switch kind {
        case .cron:
            // The hub parses the expression with a cron validator; catch the obvious shape mistakes here.
            return Self.isCronShaped(cron)

        case .device:
            guard !deviceId.isBlank, !matchKey.isBlank else { return false }
            return matchKind == .control || !matchText.isBlank
        }
    }

    var triggerSource: ScenarioTriggerSource {
        switch kind {
        case .cron:
            return .cron(ScenarioCronTrigger(cron: cron.trimmed, adjustTo: adjustTo))

        case .device:
            let match = ScenarioValueMatch(are: [matchKey.trimmed: matchedValue])
            return .device(
                ScenarioDeviceTrigger(
                    externalId: deviceId,
                    commands: matchKind == .command ? match : nil,
                    controls: matchKind == .control ? match : nil,
                    measurements: matchKind == .measurement ? match : nil
                )
            )
        }
    }

    private var matchedValue: AnyCodable {
        switch matchKind {
        case .command:
            return AnyCodable(matchText.trimmed)

        case .control:
            return AnyCodable(matchValue)

        case .measurement:
            let text = matchText.trimmed
            if let integer = Int(text) { return AnyCodable(integer) }
            if let number = Double(text) { return AnyCodable(number) }
            return AnyCodable(text)
        }
    }

    init(
        kind: ScenarioTriggerSource.Kind = .cron,
        cron: String = defaultCron,
        adjustTo: ScenarioSolarAdjustment? = nil,
        deviceId: String = "",
        matchKind: MatchKind = .control,
        matchKey: String = defaultControlKey,
        matchText: String = "",
        matchValue: Bool = true
    ) {
        self.kind = kind
        self.cron = cron
        self.adjustTo = adjustTo
        self.deviceId = deviceId
        self.matchKind = matchKind
        self.matchKey = matchKey
        self.matchText = matchText
        self.matchValue = matchValue
    }

    init(source: ScenarioTriggerSource) {
        switch source {
        case .cron(let trigger):
            self.init(kind: .cron, cron: trigger.cron, adjustTo: trigger.adjustTo)

        case .device(let trigger):
            self.init(device: trigger)
        }
    }

    /// A device source may carry several condition sections; the editor shows the first populated one.
    private init(device trigger: ScenarioDeviceTrigger) {
        if let command = Self.firstEntry(of: trigger.commands) {
            self.init(
                kind: .device,
                deviceId: trigger.externalId,
                matchKind: .command,
                matchKey: command.key,
                matchText: Self.text(of: command.value)
            )
        } else if let measurement = Self.firstEntry(of: trigger.measurements) {
            self.init(
                kind: .device,
                deviceId: trigger.externalId,
                matchKind: .measurement,
                matchKey: measurement.key,
                matchText: Self.text(of: measurement.value)
            )
        } else {
            let control = Self.firstEntry(of: trigger.controls)
            self.init(
                kind: .device,
                deviceId: trigger.externalId,
                matchKind: .control,
                matchKey: control?.key ?? Self.defaultControlKey,
                matchValue: control?.value.value as? Bool ?? true
            )
        }
    }

    private static func isCronShaped(_ expression: String) -> Bool {
        (5...6).contains(expression.split(separator: " ").count)
    }

    private static func firstEntry(of match: ScenarioValueMatch?) -> (key: String, value: AnyCodable)? {
        match?.are.sorted { $0.key < $1.key }.first
    }

    static func text(of value: AnyCodable) -> String {
        switch value.value {
        case let string as String: return string
        case let integer as Int: return "\(integer)"
        case let number as Double: return "\(number)"
        default: return ""
        }
    }
}
