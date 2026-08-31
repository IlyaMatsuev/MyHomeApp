import Foundation
import Testing
@testable import MyHomeApp

@MainActor
struct FavoriteColorsStoreTests {
    private let persistence = InMemoryFavoriteColorsPersistence()
    private let store: FavoriteColorsStore

    init() {
        store = FavoriteColorsStore(persistence: persistence)
    }

    // MARK: - Loading

    @Test
    func startsFromWhateverWasPersisted() throws {
        let saved = [FavoriteColor(hex: "#FF7A45"), FavoriteColor(hex: "#4ADE80")]
        let persistence = InMemoryFavoriteColorsPersistence(initial: saved)

        let store = FavoriteColorsStore(persistence: persistence)

        #expect(store.colors == saved)
    }

    // MARK: - Adding

    @Test
    func addsAColourAndPersistsIt() throws {
        store.add("#B7D4FF")

        #expect(store.colors.map(\.hex) == ["#B7D4FF"])
        #expect(try persistence.load().map(\.hex) == ["#B7D4FF"])
    }

    @Test
    func storesOneSpellingOfAColour() {
        store.add("b7d4ff")

        #expect(store.colors.map(\.hex) == ["#B7D4FF"])
    }

    @Test
    func ignoresAColourItAlreadyHas() {
        store.add("#B7D4FF")
        store.add("b7d4ff")

        #expect(store.colors.count == 1)
    }

    @Test
    func ignoresSomethingThatIsNotAHexColour() {
        store.add("cornflower")

        #expect(store.colors.isEmpty)
    }

    @Test
    func containsMatchesRegardlessOfSpelling() {
        store.add("#B7D4FF")

        #expect(store.contains("b7d4ff"))
        #expect(store.contains("#FF7A45") == false)
        #expect(store.contains("cornflower") == false)
    }

    // MARK: - Editing

    @Test
    func editingAColourKeepsItsPlaceInTheList() throws {
        store.add("#FF7A45")
        store.add("#4ADE80")
        let first = try #require(store.colors.first)

        store.update(first, to: "#000000")

        #expect(store.colors.map(\.hex) == ["#000000", "#4ADE80"])
        #expect(try persistence.load().map(\.hex) == ["#000000", "#4ADE80"])
    }

    @Test
    func ignoresAnEditToSomethingThatIsNotAHexColour() throws {
        store.add("#FF7A45")
        let first = try #require(store.colors.first)

        store.update(first, to: "cornflower")

        #expect(store.colors.map(\.hex) == ["#FF7A45"])
    }

    /// Editing one favourite onto another would leave two identical circles, so the edited one goes.
    @Test
    func editingAColourOntoOneAlreadySavedDropsTheDuplicate() throws {
        store.add("#FF7A45")
        store.add("#4ADE80")
        let second = try #require(store.colors.last)

        store.update(second, to: "#FF7A45")

        #expect(store.colors.map(\.hex) == ["#FF7A45"])
    }

    @Test
    func ignoresAnEditToAColourThatIsNoLongerSaved() {
        let stale = FavoriteColor(hex: "#FF7A45")
        store.add("#4ADE80")

        store.update(stale, to: "#000000")

        #expect(store.colors.map(\.hex) == ["#4ADE80"])
    }

    // MARK: - Removing

    @Test
    func removesAColourAndPersistsTheRest() throws {
        store.add("#FF7A45")
        store.add("#4ADE80")
        let first = try #require(store.colors.first)

        store.remove(first)

        #expect(store.colors.map(\.hex) == ["#4ADE80"])
        #expect(try persistence.load().map(\.hex) == ["#4ADE80"])
    }
}
