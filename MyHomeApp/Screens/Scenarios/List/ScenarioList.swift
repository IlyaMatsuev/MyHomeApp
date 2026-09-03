import SwiftUI

struct ScenarioList: View {
    let sections: [ScenarioGroupSection]

    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.scenarios) { scenario in
                        ScenarioListRow(scenario: scenario)
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
