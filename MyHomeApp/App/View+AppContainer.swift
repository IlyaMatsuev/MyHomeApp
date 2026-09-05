import SwiftUI

extension View {
    func inject(_ container: AppContainer) -> some View {
        self.environment(container)
            .environment(container.sessionStore)
            .environment(container.serverConfigStore)
            .environment(container.registrationStore)
            .environment(container.savedColorsStore)
            .environment(container.toastStore)
    }
}
