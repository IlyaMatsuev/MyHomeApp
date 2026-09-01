import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            TabView {
                DevicesView()
                    .tabItem {
                        Label("Devices", systemImage: "lightbulb.fill")
                    }
                ScenariosView()
                    .tabItem {
                        Label("Scenarios", systemImage: "wand.and.stars")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(Color("AccentPrimary"))
        }
    }
}

#Preview {
    ContentView()
}
