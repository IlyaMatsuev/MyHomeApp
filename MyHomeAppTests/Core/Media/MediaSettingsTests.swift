import Foundation
import Testing
@testable import MyHomeApp

struct MediaSettingsTests {
    // MARK: - disabled

    @Test
    func disabledTemplateIsOffAndHasNoAddress() {
        let settings = MediaSettings.disabled

        #expect(settings.enabled == false)
        #expect(settings.server.address.isEmpty)
        #expect(settings.server.remote == false)
        #expect(settings.server.label == MediaSettings.serverLabel)
    }

    // MARK: - valid / active

    @Test
    func validIsFalseWithoutAnAddress() {
        #expect(MediaSettings.disabled.valid == false)
    }

    @Test
    func validIsTrueForAHostWithPort() {
        let settings = MediaSettings(enabled: false, server: Server(.http, "192.168.1.10:8080"))

        #expect(settings.valid)
    }

    @Test
    func activeRequiresBothTheToggleAndAValidAddress() {
        let configured = Server(.http, "192.168.1.10:8080")

        #expect(MediaSettings(enabled: true, server: configured).active)
        #expect(MediaSettings(enabled: false, server: configured).active == false)
        #expect(MediaSettings(enabled: true, server: Server(.http, "")).active == false)
    }

    // MARK: - Codable

    @Test
    func roundTripsThroughJSON() throws {
        let settings = MediaSettings(enabled: true, server: Server(.https, "media.home:9000", label: "Media"))

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(MediaSettings.self, from: data)

        #expect(decoded == settings)
    }
}
