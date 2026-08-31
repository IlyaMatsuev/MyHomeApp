import SwiftUI
import Testing
@testable import MyHomeApp

struct HexColorTests {
    // MARK: - normalizedHexColor

    @Test
    func normalizesTheSpellingsOfOneColour() {
        #expect("#b7d4ff".normalizedHexColor == "#B7D4FF")
        #expect("B7D4FF".normalizedHexColor == "#B7D4FF")
        #expect("  #B7d4Ff  ".normalizedHexColor == "#B7D4FF")
    }

    @Test
    func keepsShortAndAlphaFormsAsTheyAre() {
        #expect("#abc".normalizedHexColor == "#ABC")
        #expect("#b7d4ff80".normalizedHexColor == "#B7D4FF80")
    }

    @Test
    func rejectsAnythingThatIsNotAHexColour() {
        #expect("cornflower".normalizedHexColor == nil)
        #expect("#12345".normalizedHexColor == nil)
        #expect("".normalizedHexColor == nil)
    }

    // MARK: - Color(hex:)

    @Test
    func readsEveryHexShapeTheHubAccepts() {
        #expect(Color(hex: "#B7D4FF") != nil)
        #expect(Color(hex: "B7D4FF") != nil)
        #expect(Color(hex: "#ABC") != nil)
        #expect(Color(hex: "#B7D4FF80") != nil)
        #expect(Color(hex: "cornflower") == nil)
    }

    @Test
    func expandsAShorthandColourToItsFullForm() {
        #expect(Color(hex: "#ABC")?.hexString == Color(hex: "#AABBCC")?.hexString)
    }

    // MARK: - hexString

    @Test
    func writesAColourBackAsSixDigitHex() {
        #expect(Color(red: 1, green: 0.5, blue: 0).hexString == "#FF8000")
        #expect(Color(red: 0, green: 0, blue: 0).hexString == "#000000")
    }

    @Test
    func roundTripsThroughHexUnchanged() {
        #expect(Color(hex: "#B7D4FF")?.hexString == "#B7D4FF")
    }

    /// The system picker offers Display P3, but devices only understand sRGB.
    @Test
    func clampsAWideGamutColourIntoSRGB() {
        let vivid = Color(.displayP3, red: 1, green: 0, blue: 0)

        #expect(vivid.hexString == "#FF0000")
    }
}
