import SwiftUI

struct DeviceList: View {
    let roomGroups: [DeviceRoomGroup]

    var body: some View {
        List {
            ForEach(roomGroups) { group in
                Section {
                    ForEach(group.devices) { device in
                        DeviceListRow(device: device)
                    }
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
