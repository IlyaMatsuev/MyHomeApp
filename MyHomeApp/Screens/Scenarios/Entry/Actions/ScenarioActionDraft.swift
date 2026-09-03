import Foundation
import AnyCodable

struct ScenarioActionDraft: Identifiable, Hashable {
    static let defaultControlKey = "on"

    let draftId = UUID()

    var id: UUID { draftId }

    var deviceId: String
    var controlKey: String
    var value: Bool

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
