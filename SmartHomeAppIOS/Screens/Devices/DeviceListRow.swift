import SwiftUI

struct DeviceListRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 12) {
            Text(device.type.emoji)
                .font(.title3)
                .foregroundStyle(Color("AccentPrimary"))
                .frame(width: 36, height: 36)
                .background(Color("BackgroundTertiary"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body)
                    .foregroundStyle(Color("TextPrimary"))

                Text("\(device.type.label) · \(device.brand.label)")
                    .font(.subheadline)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
    }
}
