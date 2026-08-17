import SwiftUI

struct MediaManagerSection: View {
    @State private var viewModel: MediaManagerSettingsViewModel

    init(store: MediaSettingsStore, service: any MediaService) {
        self._viewModel = State(initialValue: MediaManagerSettingsViewModel(store: store, service: service))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if viewModel.draft.enabled {
                addressField
            }

            errorText
            saveButton
        }
        .padding(16)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: viewModel.draft.enabled)
    }

    private var header: some View {
        Toggle(isOn: $viewModel.draft.enabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Media Manager")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                Text("Browse and download movies and series from your Media Manager.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .tint(Color("AccentPrimary"))
        .disabled(viewModel.saving)
    }

    private var addressField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Media Manager address")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 0) {
                schemePicker
                Divider().frame(height: 24)
                TextField("192.168.1.10:8080", text: $viewModel.draft.server.address)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
            }
            .frame(minHeight: 48)
            .background(Color("BackgroundTertiary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(viewModel.saving)

            Text("Include the port if your Media Manager uses one (e.g. :8080).")
                .font(.caption2)
                .foregroundStyle(Color("TextSecondary"))
        }
    }

    private var schemePicker: some View {
        Menu {
            Picker("Scheme", selection: $viewModel.draft.server.scheme) {
                ForEach(AddressScheme.allCases) { scheme in
                    Text(scheme.label).tag(scheme)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.draft.server.scheme.label)
                    .font(.subheadline.monospaced())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(Color("TextPrimary"))
            .padding(.horizontal, 14)
            .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var errorText: some View {
        if let message = viewModel.errorMessage {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(message).font(.footnote)
            }
            .foregroundStyle(Color("Danger"))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            ZStack {
                Text("Save")
                    .opacity(viewModel.saving ? 0 : 1)

                if viewModel.saving {
                    ProgressView().tint(.white)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color("AccentPrimary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(viewModel.canSave ? 1 : 0.5)
        }
        .disabled(!viewModel.canSave)
    }
}
