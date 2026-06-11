import Foundation
import Testing
@testable import SmartHomeAppIOS

struct MockServerConfigServiceTests {
    private let service = MockServerConfigService(operationDelay: .zero)

    @Test
    func isReachableReturnsTrueForHubHomeLocal() async {
        let server = Server(.http, "hub.home", remote: false)
        #expect(await service.isReachable(server: server))
    }

    @Test
    func isReachableAcceptsHubHomeWithPort() async {
        let server = Server(.http, "hub.home:8080", remote: false)
        #expect(await service.isReachable(server: server))
    }

    @Test
    func isReachableReturnsFalseForOtherHost() async {
        let server = Server(.http, "192.168.1.10", remote: false)
        #expect(!(await service.isReachable(server: server)))
    }

    @Test
    func isReachableReturnsFalseForRemoteHubHome() async {
        let server = Server(.https, "hub.home", remote: true)
        #expect(!(await service.isReachable(server: server)))
    }
}
