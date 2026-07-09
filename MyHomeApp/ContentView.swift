import SwiftUI

struct ContentView: View {
    @Environment(\.deviceService) private var deviceService
    @Environment(ToastStore.self) private var toastStore

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            TabView {
                DevicesView(service: deviceService, toastStore: toastStore)
                    .tabItem {
                        Label("Devices", systemImage: "lightbulb.fill")
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
