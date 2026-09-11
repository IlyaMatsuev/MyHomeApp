import SwiftUI

/// What the device reports back. Read-only — the hub owns these values.
struct DeviceMeasurementsSection: View {
    let device: Device

    var body: some View {
        CardSection(title: "Measurements", subtitle: subtitle, spacing: 10) {
            ForEach(device.measurementItems) { item in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                            .font(.subheadline)
                            .foregroundStyle(Color("TextPrimary"))

                        if let description = item.description, !description.isBlank {
                            Text(description)
                                .font(.caption2)
                                .foregroundStyle(Color("TextSecondary"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 12)

                    Text(DeviceConfigValue.text(of: device.measurementValue(of: item), for: item))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color("TextSecondary"))
                }
            }
        }
    }

    private var subtitle: String? {
        guard let updatedAt = device.measurementsUpdatedAt else { return nil }
        return "Updated \(updatedAt.formatted(.relative(presentation: .named)))"
    }
}
