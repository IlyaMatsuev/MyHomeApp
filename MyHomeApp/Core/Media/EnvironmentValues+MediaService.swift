import SwiftUI

extension EnvironmentValues {
    @Entry var mediaService: any MediaService = MockMediaService()
}
