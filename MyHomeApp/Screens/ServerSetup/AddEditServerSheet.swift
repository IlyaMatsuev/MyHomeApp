import SwiftUI

struct AddEditServerSheet: View {
    @Bindable var viewModel: ServerSetupViewModel
    @Binding var server: Server

    @State private var isAdvancedExpanded = false

    var loading: Bool { viewModel.loading }
    var errorMessage: String? { viewModel.draftErrorMessage }

    let mode: Mode

    enum Mode {
        case add
        case edit

        var title: String {
            switch self {
            case .add: return "Add Server"
            case .edit: return "Edit Server"
            }
        }
    }

    init(viewModel: ServerSetupViewModel, mode: Mode, server: Binding<Server>) {
        self.viewModel = viewModel
        self.mode = mode
        self._server = server
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()
                form
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.closeServerForm() }
                        .disabled(loading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if loading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await viewModel.saveDraft() }
                        }
                        .disabled(!viewModel.canSaveDraft)
                    }
                }
            }
        }
    }

    /// A `List` rather than a `ScrollView`, because swipe-to-delete on the header rows only works in one.
    /// The rows drop the list chrome, so the fields keep their card look.
    private var form: some View {
        List {
            Group {
                labelField
                urlField
                remoteToggle
                tip
                advancedToggle
            }
            .formRow()

            if isAdvancedExpanded {
                advancedSettings
            }

            errorText
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.vertical, 14, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, 0)
    }

    private var labelField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Label")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 0) {
                TextField("My Home", text: $server.label)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
            }
            .frame(minHeight: 48)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var urlField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Server address")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 0) {
                schemePicker
                Divider().frame(height: 24)
                TextField("192.168.1.10:8080", text: $server.address)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
            }
            .frame(minHeight: 48)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Include the port if your server uses one (e.g. :8080).")
                .font(.caption2)
                .foregroundStyle(Color("TextSecondary"))
        }
    }

    private var schemePicker: some View {
        Menu {
            Picker("Scheme", selection: $server.scheme) {
                ForEach(AddressScheme.allCases) { scheme in
                    Text(scheme.label).tag(scheme)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(server.scheme.label)
                    .font(.subheadline.monospaced())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(Color("TextPrimary"))
            .padding(.horizontal, 14)
            .frame(maxHeight: .infinity)
        }
    }

    private var remoteToggle: some View {
        Toggle(isOn: $server.remote) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Remote server")
                    .foregroundStyle(Color("TextPrimary"))
                Text("Reachable over the internet via a domain name.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .tint(Color("AccentPrimary"))
        .padding()
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(loading)
    }

    private var advancedToggle: some View {
        Button {
            withAnimation { isAdvancedExpanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                Text("Advanced settings")
                    .foregroundStyle(Color("TextPrimary"))
                Spacer()
                if !isAdvancedExpanded && filledHeaderCount > 0 {
                    Text("^[\(filledHeaderCount) header](inflect: true)")
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .rotationEffect(.degrees(isAdvancedExpanded ? 90 : 0))
            }
            .padding()
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isAdvancedExpanded ? "Expanded" : "Collapsed")
    }

    private var filledHeaderCount: Int {
        server.headers.filter { !$0.isBlank }.count
    }

    @ViewBuilder
    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Custom HTTP headers")
                .font(.footnote)
                .foregroundStyle(Color("TextPrimary"))
            Text("Sent with every request to this server, e.g. a token your reverse proxy checks. Swipe left on a header to delete it.")
                .font(.caption)
                .foregroundStyle(Color("TextSecondary"))
        }
        .formRow()

        ForEach($server.headers) { $header in
            ServerHeaderRow(
                header: $header,
                nameError: viewModel.headerNameError(for: header),
                valueError: viewModel.headerValueError(for: header)
            )
            .disabled(loading)
            .formRow()
        }
        .onDelete(perform: viewModel.removeDraftHeaders)
        .deleteDisabled(loading)

        addHeaderButton
            .formRow()
    }

    private var addHeaderButton: some View {
        Button {
            withAnimation { viewModel.addDraftHeader() }
        } label: {
            Label("Add header", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AccentPrimary"))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(loading)
    }

    @ViewBuilder
    private var errorText: some View {
        if let message = errorMessage {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(message).font(.footnote)
            }
            .foregroundStyle(Color("Danger"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .formRow()
        }
    }

    private var tip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: server.remote ? "globe" : "wifi")
            Text(tipText).font(.footnote)
        }
        .foregroundStyle(Color("TextSecondary"))
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tipText: String {
        if server.remote {
            "Make sure the URL is reachable over the internet from outside your home network."
        } else {
            "Make sure your phone is connected to the same Wi-Fi network as the server."
        }
    }
}

private extension View {
    func formRow() -> some View {
        listRowInsets(EdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
