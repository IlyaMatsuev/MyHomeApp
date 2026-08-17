import Testing
@testable import MyHomeApp

struct MediaKindFilterTests {
    // MARK: - allFilters

    @Test
    func allFiltersStartsWithAllAndCoversEveryKind() {
        #expect(MediaKindFilter.allFilters == [.all, .specific(.movie), .specific(.series)])
    }

    // MARK: - label

    @Test
    func labelUsesThePluralKindName() {
        #expect(MediaKindFilter.all.label == "All")
        #expect(MediaKindFilter.specific(.movie).label == "Movies")
        #expect(MediaKindFilter.specific(.series).label == "Series")
    }

    // MARK: - queryValue

    @Test
    func queryValueIsNilForAll() {
        #expect(MediaKindFilter.all.queryValue == nil)
    }

    @Test
    func queryValueIsTheRawKindForSpecificFilters() {
        #expect(MediaKindFilter.specific(.movie).queryValue == "movie")
        #expect(MediaKindFilter.specific(.series).queryValue == "series")
    }
}
