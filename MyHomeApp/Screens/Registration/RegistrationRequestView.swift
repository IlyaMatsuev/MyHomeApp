import SwiftUI

struct RegistrationRequestView: View {
    @Environment(RegistrationStore.self) private var registrationStore
    @State private var viewModel: RegistrationRequestViewModel?

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            if let viewModel {
                RegistrationRequestForm(viewModel: viewModel)
            }
        }
        .navigationTitle("Request Access")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = RegistrationRequestViewModel(registrationStore: registrationStore)
            }
        }
    }
}

#Preview {
    let registrationStore = RegistrationStore(
        service: MockRegistrationService(operationDelay: .zero),
        persistence: InMemoryRegistrationPersistence()
    )
    return NavigationStack {
        RegistrationRequestView()
            .environment(registrationStore)
    }
}
