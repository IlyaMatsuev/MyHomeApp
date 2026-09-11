import SwiftUI

@main
struct MyHomeApp: App {
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .toastOverlay()
                .inject(container)
        }
    }
}
