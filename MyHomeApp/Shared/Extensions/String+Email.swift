import Foundation

extension String {
    private static let emailRegex = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/

    var isValidEmail: Bool {
        (try? Self.emailRegex.wholeMatch(in: self)) != nil
    }
}
