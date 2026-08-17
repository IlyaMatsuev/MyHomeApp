import SwiftUI

struct MediaKindFilterList: View {
    @Binding var selection: MediaKindFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MediaKindFilter.allFilters, id: \.self) { filter in
                    FilterChip(title: filter.label, isSelected: selection == filter) {
                        selection = filter
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }
}
