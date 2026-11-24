import Foundation

/// URLSession drops `Authorization` on redirects but forwards every other header, even to another host,
/// and a server's custom headers are credentials too.
final class ServerHeaderRedirectGuard: NSObject, URLSessionTaskDelegate {
    private let host: String?
    private let headerNames: [String]

    init(server: Server) {
        host = server.baseURL?.host()?.lowercased()
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
        if request.url?.host()?.lowercased() != host {
            for name in headerNames {
                request.setValue(nil, forHTTPHeaderField: name)
            }
        }
        completionHandler(request)
    }
}
