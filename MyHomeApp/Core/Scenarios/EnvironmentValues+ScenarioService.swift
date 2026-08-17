import SwiftUI

extension EnvironmentValues {
    @Entry var scenarioService: any ScenarioService = MockScenarioService()
}
