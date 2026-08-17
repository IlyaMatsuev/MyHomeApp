import Foundation
import AnyCodable

/// Editor-side representation of one `ScenarioTriggerSource`.
///
/// The wire model is an enum with associated values, which SwiftUI cannot bind into. The draft is
/// therefore flat: every field for every kind lives side by side and `kind` decides which ones count.
struct ScenarioSourceDraft: Identifiable, Hashable {
    /// Which half of a device trigger is being matched — `commands.are` or `controls.are`.
    enum MatchKind: String, Hashable, CaseIterable, Identifiable {
        case command
        case control

        var id: String { rawValue }

        var label: String {
            switch self {
            case .command: return "Sends a command"
            case .control: return "Has a control value"
            }
        }
    }

    static let defaultCron = "0 8 * * *"
    static let defaultCommandKey = "action"
    static let defaultControlKey = "on"

    let id = UUID()

    var kind: ScenarioTriggerSource.Kind

    var cron: String
    var adjustTo: ScenarioSolarAdjustment?

    var deviceId: String
    var matchKind: MatchKind
    var matchKey: String
    var matchCommand: String
    var matchValue: Bool

    var isValid: Bool {
        switch kind {
        case .cron:
            return !cron.isBlank

        case .device:
            guard !deviceId.isBlank, !matchKey.isBlank else { return false }
            return matchKind == .control || !matchCommand.isBlank
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
                    controls: matchKind == .control ? match : nil
                )
            )
        }
    }

    private var matchedValue: AnyCodable {
        switch matchKind {
        case .command: return AnyCodable(matchCommand.trimmed)
        case .control: return AnyCodable(matchValue)
        }
    }

    init(
        kind: ScenarioTriggerSource.Kind = .cron,
        cron: String = defaultCron,
        adjustTo: ScenarioSolarAdjustment? = nil,
        deviceId: String = "",
        matchKind: MatchKind = .control,
        matchKey: String = defaultControlKey,
        matchCommand: String = "",
        matchValue: Bool = true
    ) {
        self.kind = kind
        self.cron = cron
        self.adjustTo = adjustTo
        self.deviceId = deviceId
        self.matchKind = matchKind
        self.matchKey = matchKey
        self.matchCommand = matchCommand
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

    private init(device trigger: ScenarioDeviceTrigger) {
        // A device trigger matches either commands or controls; commands win when both are present.
        if let command = Self.firstEntry(of: trigger.commands) {
            self.init(
                kind: .device,
                deviceId: trigger.externalId,
                matchKind: .command,
                matchKey: command.key,
                matchCommand: command.value.value as? String ?? ""
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

    private static func firstEntry(of match: ScenarioValueMatch?) -> (key: String, value: AnyCodable)? {
        match?.are.sorted { $0.key < $1.key }.first
    }
}
