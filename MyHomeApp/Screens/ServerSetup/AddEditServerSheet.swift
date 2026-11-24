import SwiftUI

struct AddEditServerSheet: View {
    @Bindable var viewModel: ServerSetupViewModel
    @Binding var server: Server

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

    private var form: some View {
        List {
            Group {
                Section {
                    labelField
                } header: {
                    Text("Label").foregroundStyle(Color("TextSecondary"))
                }

                Section {
                    addressField
                } header: {
                    Text("Server address").foregroundStyle(Color("TextSecondary"))
                } footer: {
                    Text("Include the port if your server uses one (e.g. :8080).")
                        .foregroundStyle(Color("TextSecondary"))
                }

                Section {
                    remoteToggle
                } footer: {
                    Label(tipText, systemImage: server.remote ? "globe" : "wifi")
                        .foregroundStyle(Color("TextSecondary"))
                }

                Section {
                    advancedSettings
                }
            }
            .listRowBackground(Color("BackgroundSecondary"))
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .disabled(loading)
        .safeAreaInset(edge: .bottom) { errorText }
    }

    private var labelField: some View {
        TextField("My Home", text: $server.label)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    private var addressField: some View {
        HStack(spacing: 0) {
            schemePicker
            Divider().frame(height: 24)
            TextField("192.168.1.10:8080", text: $server.address)
                .textContentType(.URL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.leading, 12)
        }
        .listRowInsets(.vertical, 4)
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
            .padding(.trailing, 14)
            .frame(minHeight: 44)
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
    }

    private var advancedSettings: some View {
        DisclosureGroup("Advanced settings") {
            ForEach($server.headers) { $header in
                VStack(spacing: 8) {
                    FormTextField(title: "Name", placeholder: "Header name", text: $header.name, isMonospaced: true)
                    FormTextField(
                        title: "Value",
                        placeholder: "Header value",
                        text: $header.value,
                        isMonospaced: true,
                        isSecure: true
                    )
                }
                .keyboardType(.asciiCapable)
            }
            .onDelete(perform: viewModel.removeHeaders)

            Button("Add header", systemImage: "plus", action: viewModel.addHeader)
                .foregroundStyle(Color("AccentPrimary"))
        }
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
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color("BackgroundPrimary"))
        }
    }

    private var tipText: String {
        if server.remote {
            "Make sure the URL is reachable over the internet from outside your home network."
        } else {
            "Make sure your phone is connected to the same Wi-Fi network as the server."
        }
    }
}

#Preview {
    @Previewable @State var viewModel = AppContainer.preview().build().buildServerSetupViewModel(mode: .edit)

    AddEditServerSheet(viewModel: viewModel, mode: .edit, server: $viewModel.draftServer)
}
