import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                DevicesView()
                    .tabItem {
                        Label("Devices", systemImage: "lightbulb.fill")
                    }
            }
            .tint(Color("AccentPrimary"))
        }
        
    }
}

#Preview {
    ContentView()
}
