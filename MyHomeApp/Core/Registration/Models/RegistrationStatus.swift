enum RegistrationStatus: String, Codable, Equatable, Sendable, CaseIterable {
    case pending
    case approved
    case rejected

    var label: String {
        switch self {
        case .pending: "Pending review"
        case .approved: "Approved"
        case .rejected: "Rejected"
        }
    }

    var detail: String {
        switch self {
        case .pending: "Your request is waiting for the hub owner to approve it. You can come back later to check again."
        case .approved: "Your request was approved. You can now sign in with the credentials sent to your email."
        case .rejected: "Your request was rejected. Reach out to the hub owner if you think this was a mistake."
        }
    }
}
