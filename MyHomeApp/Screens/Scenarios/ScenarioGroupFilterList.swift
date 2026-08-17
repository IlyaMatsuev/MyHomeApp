import SwiftUI

struct ScenarioGroupFilterList: View {
    private typealias Chip = FilterChipsBar<ScenarioGroupFilter>.Chip

    let availableGroups: [ScenarioGroup]
    @Binding var selection: ScenarioGroupFilter

    var body: some View {
        FilterChipsBar(chips: chips, selection: $selection)
    }

    private var chips: [Chip] {
        [Chip(.all, label: ScenarioGroupFilter.all.label)]
            + availableGroups.map { Chip(.specific($0), label: $0.label) }
    }
}
