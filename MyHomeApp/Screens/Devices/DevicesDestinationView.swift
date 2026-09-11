import SwiftUI

struct DevicesDestinationView: View {
    let router: DevicesRouter
    let destination: DevicesRouter.Destination
    let viewModel: DevicesViewModel

    var body: some View {
        switch destination {
        case .edit(let deviceId):
            if let device = viewModel.device(withId: deviceId) {
                DeviceDetailSheet(
                    device: device,
                    onChanged: { viewModel.replaceDevice($0) },
                    onDeleted: {
                        viewModel.removeDevice(withId: $0)
                        router.dismiss()
                    }
                )
            }
        }
    }
}
