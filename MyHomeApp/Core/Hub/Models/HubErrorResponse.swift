import Foundation

struct HubErrorEntry: Sendable, Decodable {
    let message: String
    let path: String
}

struct HubErrorDetails: Sendable, Decodable {
    let errors: [HubErrorEntry]
}

struct HubErrorResponse: Sendable, Decodable {
    let messages: [String]
    let details: HubErrorDetails
    let statusCode: Int
}
