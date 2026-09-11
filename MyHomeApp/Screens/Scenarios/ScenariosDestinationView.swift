import SwiftUI

struct ScenariosDestinationView: View {
    let router: ScenariosRouter
    let destination: ScenariosRouter.Destination
    let viewModel: ScenariosViewModel

    var body: some View {
        switch destination {
        case .create:
            editor(mode: .create, draft: ScenarioDraft())

        case .edit(let scenarioId):
            if let scenario = viewModel.scenario(withId: scenarioId) {
                editor(mode: .edit(scenarioId), draft: ScenarioDraft(scenario: scenario))
            }
        }
    }

    private func editor(mode: ScenarioEditorViewModel.Mode, draft: ScenarioDraft) -> some View {
        ScenarioEditorSheet(
            mode: mode,
            draft: draft,
            devices: viewModel.devices,
            knownGroups: viewModel.knownGroups,
            knownCommands: viewModel.knownCommands,
            onChanged: {
                viewModel.mergeScenario($0)
                router.dismiss()
            }
        )
    }
}
