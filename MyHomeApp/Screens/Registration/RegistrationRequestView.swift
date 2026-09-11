import SwiftUI

struct RegistrationRequestView: View {
    @Environment(AppContainer.self) private var container
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
                    registrationStore: container.registrationStore,
                    email: email,
                    comment: comment
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegistrationRequestView(onSubmitted: {}, onAlreadyApproved: {})
            .inject(AppContainer.preview().build())
    }
}
