import SwiftUI

struct ScenarioEditorSheet: View {
    @Bindable var viewModel: ScenarioEditorViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()
                form
            }
            .navigationTitle(viewModel.mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                detailsSection
                triggerSection
                actionsSection
                errorText
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .disabled(viewModel.loading)
        }
        ToolbarItem(placement: .confirmationAction) {
            if viewModel.loading {
                ProgressView()
            } else {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.canSave)
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        card {
            FormTextField(
                title: "Name",
                placeholder: "Warm light on",
                text: $viewModel.draft.name,
                autocapitalization: .sentences
            )
            FormTextField(
                title: "Description",
                placeholder: "Optional",
                text: $viewModel.draft.description,
                autocapitalization: .sentences
            )
            groupField
            Toggle("Active", isOn: $viewModel.draft.active)
                .tint(Color("AccentPrimary"))
                .foregroundStyle(Color("TextPrimary"))
        }
    }

    private var groupField: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormTextField(title: "Group", placeholder: "General", text: $viewModel.draft.group)

            if !viewModel.knownGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.knownGroups) { group in
                            groupSuggestion(group)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    private func groupSuggestion(_ group: ScenarioGroup) -> some View {
        Button {
            viewModel.draft.group = group.isGeneral ? "" : group.rawValue
        } label: {
            Text(group.label)
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundStyle(Color("TextSecondary"))
                .background(Capsule().fill(Color("BackgroundTertiary")))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Triggers

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("When")
                Spacer()
                addTriggerMenu
            }

            if viewModel.draft.sources.isEmpty {
                hint("Add at least one trigger — a schedule or something a device does.")
            } else {
                sourceCards
                if viewModel.showsLogicEditor {
                    logicCard
                }
            }
        }
    }

    private var addTriggerMenu: some View {
        Menu {
            ForEach(ScenarioTriggerSource.Kind.allCases) { kind in
                Button {
                    viewModel.addSource(kind: kind)
                } label: {
                    Label(kind.label, systemImage: kind.iconSystemName)
                }
            }
        } label: {
            Label("Add trigger", systemImage: "plus.circle.fill")
                .font(.subheadline)
                .foregroundStyle(Color("AccentPrimary"))
        }
    }

    private var sourceCards: some View {
        ForEach($viewModel.draft.sources) { $source in
            ScenarioSourceCard(viewModel: viewModel, source: $source, number: number(of: source))
        }
    }

    /// Position of a source in the trigger — the number a custom logic expression refers to.
    private func number(of source: ScenarioSourceDraft) -> Int {
        (viewModel.draft.sources.firstIndex { $0.id == source.id } ?? 0) + 1
    }

    private var logicCard: some View {
        card {
            Text("These triggers together")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))

            Picker("Match", selection: $viewModel.draft.logicMode) {
                ForEach(ScenarioTriggerLogic.Mode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.draft.logicMode == .custom {
                customLogicField
            }
        }
    }

    private var customLogicField: some View {
        VStack(alignment: .leading, spacing: 6) {
            FormTextField(
                title: "Expression",
                placeholder: "(1 OR 2) AND 3",
                text: $viewModel.draft.customLogic,
                isMonospaced: true
            )

            if let message = viewModel.logicErrorMessage {
                errorLabel(message)
            } else {
                hint("Refer to the triggers by their number, e.g. (1 OR 2) AND 3.")
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Then")
                Spacer()
                Button {
                    viewModel.addAction()
                } label: {
                    Label("Add action", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color("AccentPrimary"))
                }
            }

            if viewModel.draft.actions.isEmpty {
                hint("Add at least one device to change when the scenario fires.")
            } else {
                actionCards
            }
        }
    }

    private var actionCards: some View {
        ForEach($viewModel.draft.actions) { $action in
            ScenarioActionCard(viewModel: viewModel, action: $action)
        }
    }

    // MARK: - Building blocks

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color("TextPrimary"))
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorLabel(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.footnote)
        }
        .foregroundStyle(Color("Danger"))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var errorText: some View {
        if let message = viewModel.errorMessage {
            errorLabel(message)
        }
    }
}

#Preview("Create") {
    ScenarioEditorSheet(
        viewModel: ScenarioEditorViewModel(
            mode: .create,
            draft: ScenarioDraft(),
            devices: MockDeviceService.allDevices,
            knownGroups: [ScenarioGroup("living_room")],
            service: MockScenarioService(),
            onSaved: { _ in }
        )
    )
}

#Preview("Edit") {
    let scenario = MockScenarioService.allScenarios[0]
    return ScenarioEditorSheet(
        viewModel: ScenarioEditorViewModel(
            mode: .edit(scenario.externalId),
            draft: ScenarioDraft(scenario: scenario),
            devices: MockDeviceService.allDevices,
            knownGroups: [scenario.displayGroup],
            service: MockScenarioService(),
            onSaved: { _ in }
        )
    )
}
