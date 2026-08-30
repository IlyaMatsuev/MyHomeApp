import Foundation
import AnyCodable

/// Editor-side representation of one `ScenarioAction`.
///
/// Carries a `UUID` because several actions may target the same device, which makes the
/// device id unusable as a `ForEach` identity.
struct ScenarioActionDraft: Identifiable, Hashable {
    static let defaultControlKey = "on"

    let id = UUID()

    var deviceId: String
    var controlKey: String
    var value: Bool

    /// Measurement setters the editor has no UI for, carried through so editing a scenario
    /// created elsewhere doesn't drop them.
    private let measurements: [String: AnyCodable]

    var isValid: Bool {
        !deviceId.isBlank && !controlKey.isBlank
    }

    var action: ScenarioAction {
        ScenarioAction(
            externalId: deviceId,
            set: ScenarioActionSet(controls: [controlKey.trimmed: AnyCodable(value)], measurements: measurements)
        )
    }

    init(deviceId: String = "", controlKey: String = defaultControlKey, value: Bool = true) {
        self.init(deviceId: deviceId, controlKey: controlKey, value: value, measurements: [:])
    }

    init(action: ScenarioAction) {
        let control = action.set.controls.sorted { $0.key < $1.key }.first
        self.init(
            deviceId: action.externalId,
            controlKey: control?.key ?? Self.defaultControlKey,
            value: control?.value.value as? Bool ?? true,
            measurements: action.set.measurements
        )
    }

    private init(deviceId: String, controlKey: String, value: Bool, measurements: [String: AnyCodable]) {
        self.deviceId = deviceId
        self.controlKey = controlKey
        self.value = value
        self.measurements = measurements
    }
}
