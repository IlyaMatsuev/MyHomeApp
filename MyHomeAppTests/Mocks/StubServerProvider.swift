import Foundation
@testable import MyHomeApp

@MainActor
final class StubServerProvider: ServerProvider {
    var selectedServer: Server?

    init(selectedServer: Server? = nil) {
        self.selectedServer = selectedServer
    }
}
