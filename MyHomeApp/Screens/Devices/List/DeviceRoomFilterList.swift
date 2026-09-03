import SwiftUI

struct DeviceRoomFilterList: View {
    private typealias Chip = FilterChipsBar<DeviceRoomFilter>.Chip

    let availableRooms: [DeviceRoom]
    @Binding var selection: DeviceRoomFilter

    var body: some View {
        FilterChipsBar(chips: chips, selection: $selection)
    }

    private var chips: [Chip] {
        [Chip(.all, label: DeviceRoomFilter.all.label)]
            + availableRooms.map { Chip(.specific($0), label: $0.label) }
    }
}
