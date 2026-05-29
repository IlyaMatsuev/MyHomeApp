import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            Text("Settings")
                .foregroundStyle(Color("TextPrimary"))
        }
    }
}

#Preview {
    SettingsView()
}
