import SwiftUI

struct DeviceList: View {
    let roomGroups: [DeviceRoomGroup]

    var body: some View {
        List {
            ForEach(roomGroups) { group in
                Section {
                    ForEach(group.devices) { DeviceListRow(device: $0) }
                } header: {
                    Text("\(group.title) · \(group.devices.count)")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundPrimary"))
    }
}
