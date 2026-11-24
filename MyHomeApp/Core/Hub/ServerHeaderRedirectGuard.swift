import Foundation

/// This is a security measure to prevent sharing the custom headers if the request is being redirected to another domain, when setting up a server
/// By default URLSession does it for `Authorization` header
final class ServerHeaderRedirectGuard: NSObject, URLSessionTaskDelegate {
    private let host: String?
    private let headerNames: [String]

    init(server: Server) {
        host = Self.formatHost(url: server.baseURL)
        headerNames = server.headers.map(\.name)
    }

    func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        willPerformHTTPRedirection _: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        var request = request
        if Self.formatHost(url: request.url) != host {
            for name in headerNames {
                request.setValue(nil, forHTTPHeaderField: name)
            }
        }
        completionHandler(request)
    }

    static func formatHost(url: URL?) -> String? {
        url?.host()?.lowercased()
    }
}
