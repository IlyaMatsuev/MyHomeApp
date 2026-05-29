import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            Text("Home")
                .foregroundStyle(Color("TextPrimary"))
        }
    }
}

#Preview {
    HomeView()
}
