import Foundation
@testable import SmartHomeAppIOS

extension AuthToken {
    static func fixture(
        externalId: String = "test-external-id",
        accessToken: String = "test-access-token",
        refreshToken: String = "test-refresh-token"
    ) -> AuthToken {
        AuthToken(
            externalId: externalId,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}
