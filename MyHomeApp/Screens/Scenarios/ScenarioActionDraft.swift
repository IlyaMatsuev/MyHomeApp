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

    var isValid: Bool {
        !deviceId.isBlank && !controlKey.isBlank
    }

    var action: ScenarioAction {
        ScenarioAction(
            externalId: deviceId,
            set: ScenarioActionSet(controls: [controlKey.trimmed: AnyCodable(value)])
        )
    }

    init(deviceId: String = "", controlKey: String = defaultControlKey, value: Bool = true) {
        self.deviceId = deviceId
        self.controlKey = controlKey
        self.value = value
    }

    init(action: ScenarioAction) {
        let control = action.set.controls.sorted { $0.key < $1.key }.first
        self.init(
            deviceId: action.externalId,
            controlKey: control?.key ?? Self.defaultControlKey,
            value: control?.value.value as? Bool ?? true
        )
    }
}
