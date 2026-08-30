import SwiftUI

struct ContentView: View {
    @Environment(\.deviceService) private var deviceService
    @Environment(\.scenarioService) private var scenarioService
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
                ScenariosView(service: scenarioService, deviceService: deviceService, toastStore: toastStore)
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
