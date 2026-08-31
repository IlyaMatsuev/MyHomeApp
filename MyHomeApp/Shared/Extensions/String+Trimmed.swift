import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmed.isEmpty
    }

    /// `nil` for a blank string, so an untouched optional form field is left out of a request body.
    var nilWhenBlank: String? {
        isBlank ? nil : self
    }
}
