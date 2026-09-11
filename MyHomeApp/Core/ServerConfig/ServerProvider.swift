import Foundation

@MainActor
protocol ServerProvider {
    var selectedServer: Server? { get }
}
