import SwiftUI

struct ScenarioList: View {
    let sections: [ScenarioGroupSection]
    let viewModel: ScenariosViewModel
    let onEditScenario: (Scenario) -> Void

    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.scenarios) {
                        ScenarioListRow(scenario: $0, viewModel: viewModel, onEditScenario: onEditScenario)
                    }
                } header: {
                    Text("\(section.title) · \(section.scenarios.count)")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundPrimary"))
    }
}
