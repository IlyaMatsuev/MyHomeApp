import Foundation

struct HubRequest: Sendable {
    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    let method: Method
    let uri: String
    let body: Data?
    let protected: Bool
}

extension HubRequest {
    static func get(_ uri: String, protected: Bool = true) -> Self {
        .init(method: .get, uri: uri, body: nil, protected: protected)
    }

    static func delete(_ uri: String, protected: Bool = true) -> Self {
        .init(method: .delete, uri: uri, body: nil, protected: protected)
    }

    static func post(_ uri: String, _ body: some Encodable, protected: Bool = true) throws -> Self {
        .init(method: .post, uri: uri, body: try JSONEncoder().encode(body), protected: protected)
    }

    static func put(_ uri: String, _ body: some Encodable, protected: Bool = true) throws -> Self {
        .init(method: .put, uri: uri, body: try JSONEncoder().encode(body), protected: protected)
    }
}
