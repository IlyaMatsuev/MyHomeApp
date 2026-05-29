import SwiftUI

struct ScenariosView: View {
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            Text("Scenarios")
                .foregroundStyle(Color("TextPrimary"))
        }
    }
}

#Preview {
    ScenariosView()
}
