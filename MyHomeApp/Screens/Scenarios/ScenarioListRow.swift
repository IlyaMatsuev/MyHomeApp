import SwiftUI

struct ScenarioListRow: View {
    let scenario: Scenario

    @Environment(ScenariosViewModel.self) private var viewModel

    var busy: Bool { viewModel.isBusy(scenario) }

    var body: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 2) {
                Text(scenario.name)
                    .font(.body)
                    .foregroundStyle(Color("TextPrimary"))

                if let description = scenario.description, !description.isBlank {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color("TextSecondary"))
                        .lineLimit(2)
                }

                Text(summary)
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
            }

            Spacer(minLength: 12)

            activeToggle
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.startEditing(scenario) }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.requestDeletion(of: scenario)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(busy)
        }
    }

    private var icon: some View {
        Image(systemName: "wand.and.stars")
            .font(.title3)
            .foregroundStyle(scenario.active ? Color("AccentPrimary") : Color("TextSecondary"))
            .frame(width: 36, height: 36)
            .background(Color("BackgroundTertiary"))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var activeToggle: some View {
        HStack(spacing: 6) {
            if busy {
                ProgressView().controlSize(.small)
            }
            Toggle("", isOn: Binding(
                get: { scenario.active },
                set: { newValue in
                    Task { await viewModel.setActive(scenario, to: newValue) }
                }
            ))
            .labelsHidden()
            .tint(Color("AccentPrimary"))
            .disabled(busy)
            .accessibilityLabel("Active")
        }
    }

    private var summary: String {
        let triggers = scenario.trigger.sources.count
        let actions = scenario.actions.count
        return "\(triggers) \(triggers == 1 ? "trigger" : "triggers") · \(actions) \(actions == 1 ? "action" : "actions")"
    }
}
