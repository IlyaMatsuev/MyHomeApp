import SwiftUI

struct DevicesDestinationView: View {
    let destination: DevicesRouter.Destination
    let viewModel: DevicesViewModel
    let router: DevicesRouter

    var body: some View {
        switch destination {
        case .deviceDetails(let deviceId):
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
