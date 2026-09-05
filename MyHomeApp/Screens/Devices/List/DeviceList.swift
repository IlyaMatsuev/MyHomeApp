import SwiftUI

struct DeviceList: View {
    let roomGroups: [DeviceRoomGroup]
    let viewModel: DevicesViewModel
    let onOpenDetails: (Device) -> Void

    var body: some View {
        List {
            ForEach(roomGroups) { group in
                Section {
                    ForEach(group.devices) { device in
                        DeviceListRow(device: device, viewModel: viewModel, onOpenDetails: onOpenDetails)
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
