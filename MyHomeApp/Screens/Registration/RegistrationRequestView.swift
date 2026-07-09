import SwiftUI

struct RegistrationRequestView: View {
    @Environment(RegistrationStore.self) private var registrationStore
    @State private var viewModel: RegistrationRequestViewModel?
    var email: String = ""
    var comment: String = ""
    var onSubmitted: () -> Void
    var onAlreadyApproved: () -> Void

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            if let viewModel {
                RegistrationRequestForm(
                    viewModel: viewModel,
                    onSubmitted: onSubmitted,
                    onAlreadyApproved: onAlreadyApproved
                )
            }
        }
        .navigationTitle("Request Access")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = RegistrationRequestViewModel(
                    registrationStore: registrationStore,
                    email: email,
                    comment: comment
                )
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
        RegistrationRequestView(onSubmitted: {}, onAlreadyApproved: {})
            .environment(registrationStore)
    }
}
