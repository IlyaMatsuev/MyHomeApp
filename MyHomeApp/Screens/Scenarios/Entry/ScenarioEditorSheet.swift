import SwiftUI

@MainActor
struct ScenarioEditorSheet: View {
    let mode: ScenarioEditorViewModel.Mode
    let draft: ScenarioDraft
    let devices: [Device]
    let knownGroups: [String]
    let knownCommands: [ScenarioKnownCommand]
    let onChanged: @MainActor (Scenario) -> Void

    @Environment(AppContainer.self) private var container
    @State private var viewModel: ScenarioEditorViewModel?

    var body: some View {
        Group {
            if let viewModel {
                ScenarioEditorScreen(viewModel: viewModel)
            } else {
                ZStack {
                    Color("BackgroundPrimary").ignoresSafeArea()
                    ProgressView()
                }
            }
        }
        .onAppear {
            guard viewModel == nil else { return }
            viewModel = container.buildScenarioEditorViewModel(
                mode: mode,
                draft: draft,
                devices: devices,
                knownGroups: knownGroups,
                knownCommands: knownCommands,
                onChanged: onChanged,
            )
        }
    }
}

#Preview {
    ScenarioEditorSheet(
        mode: .create,
        draft: ScenarioDraft(),
        devices: MockDeviceService.allDevices,
        knownGroups: ["living_room"],
        knownCommands: [],
        onChanged: { _ in }
    )
    .inject(AppContainer.preview().build())
}
