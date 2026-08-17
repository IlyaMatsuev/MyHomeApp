import Foundation
@testable import MyHomeApp

final class StubMediaSettingsPersistence: MediaSettingsPersistence, @unchecked Sendable {
    var loadResult: Result<MediaSettings?, Error> = .success(nil)
    var saveError: Error?
    var clearError: Error?

    private(set) var savedSettings: [MediaSettings] = []
    private(set) var clearCallCount = 0

    func load() throws -> MediaSettings? {
        try loadResult.get()
    }

    func save(_ settings: MediaSettings) throws {
        if let saveError { throw saveError }
        savedSettings.append(settings)
    }

    func clear() throws {
        clearCallCount += 1
        if let clearError { throw clearError }
    }
}
