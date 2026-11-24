@testable import MyHomeApp

extension Server {
    func withHeaders(_ headers: ServerHeader...) -> Server {
        var copy = self
        copy.headers = headers
        return copy
    }
}
