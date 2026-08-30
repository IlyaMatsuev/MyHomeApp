import Foundation
import AnyCodable
@testable import MyHomeApp

extension Scenario {
    /// Entry point for the fluent scenario fixture builder.
    ///
    /// ```swift
    /// let scenario = Scenario.fixture(name: "Warm light on")
    ///     .inGroup("living_room")
    ///     .withCron("8 21 * * *", adjustTo: .sunset)
    ///     .withDeviceControl(deviceId: "device-1", value: false)
    ///     .withLogic("1 AND 2")
    ///     .withAction(deviceId: "device-1", value: true)
    ///     .build()
    /// ```
    static func fixture(name: String = "Test Scenario", active: Bool = true) -> ScenarioFixtureBuilder {
        ScenarioFixtureBuilder(name: name, active: active)
    }
}

final class ScenarioFixtureBuilder {
    private var externalId = UUID().uuidString
    private let name: String
    private let active: Bool

    private var description: String?
    private var group: String?
    private var repeatTimes: Int?
    private var sources: [ScenarioTriggerSource] = []
    private var actions: [ScenarioAction] = []
    private var logic: String?

    private var createdAt = Date(timeIntervalSince1970: 0)
    private var updatedAt = Date(timeIntervalSince1970: 0)

    fileprivate init(name: String, active: Bool) {
        self.name = name
        self.active = active
    }

    func withId(_ externalId: String) -> Self {
        self.externalId = externalId
        return self
    }

    func withDescription(_ description: String) -> Self {
        self.description = description
        return self
    }

    func inGroup(_ group: String) -> Self {
        self.group = group
        return self
    }

    func repeating(_ repeatTimes: Int) -> Self {
        self.repeatTimes = repeatTimes
        return self
    }

    func withCron(_ cron: String, adjustTo: ScenarioSolarAdjustment? = nil) -> Self {
        sources.append(.cron(ScenarioCronTrigger(cron: cron, adjustTo: adjustTo)))
        return self
    }

    func withDeviceCommand(deviceId: String, key: String = "action", value: String) -> Self {
        sources.append(
            .device(
                ScenarioDeviceTrigger(
                    externalId: deviceId,
                    commands: ScenarioValueMatch(are: [key: AnyCodable(value)])
                )
            )
        )
        return self
    }

    func withDeviceControl(deviceId: String, key: String = "on", value: Bool) -> Self {
        sources.append(
            .device(
                ScenarioDeviceTrigger(
                    externalId: deviceId,
                    controls: ScenarioValueMatch(are: [key: AnyCodable(value)])
                )
            )
        )
        return self
    }

    func withDeviceMeasurement(deviceId: String, key: String = "temperature", value: Int) -> Self {
        sources.append(
            .device(
                ScenarioDeviceTrigger(
                    externalId: deviceId,
                    measurements: ScenarioValueMatch(are: [key: AnyCodable(value)])
                )
            )
        )
        return self
    }

    func withLogic(_ logic: String) -> Self {
        self.logic = logic
        return self
    }

    func withAction(deviceId: String, key: String = "on", value: Bool) -> Self {
        actions.append(
            ScenarioAction(
                externalId: deviceId,
                set: ScenarioActionSet(controls: [key: AnyCodable(value)])
            )
        )
        return self
    }

    func withTimestamps(createdAt: Date, updatedAt: Date) -> Self {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        return self
    }

    func build() -> Scenario {
        Scenario(
            externalId: externalId,
            name: name,
            description: description,
            trigger: ScenarioTrigger(
                sources: sources,
                logic: logic ?? ScenarioTriggerLogic.all.expression(sourceCount: sources.count)
            ),
            actions: actions,
            active: active,
            group: group,
            repeatTimes: repeatTimes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
