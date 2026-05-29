import SwiftUI

struct DevicesView: View {
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            Text("Devices")
                .foregroundStyle(Color("TextPrimary"))
        }
    }
}

#Preview {
    DevicesView()
}
