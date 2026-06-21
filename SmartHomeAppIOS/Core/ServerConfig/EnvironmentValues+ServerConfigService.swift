import SwiftUI

extension EnvironmentValues {
    @Entry var serverConfigService: any ServerConfigService = MockServerConfigService()
}
