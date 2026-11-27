import Foundation

extension MyHomeAPIClient {
    /// Requests every page of a paginated hub endpoint in order and returns their items, overriding any
    /// `page` / `pageSize` already in the request's query.
    func sendAllPages<Item: Codable & Hashable & Sendable>(_ request: HubRequest) async throws -> [Item] {
        var items: [Item] = []
        var pageNumber = 1
        while true {
            let page: Page<Item> = try await send(request.paged(pageNumber))
            items += page.items
            // `<` rather than `!=`: the hub reports `totalPages == 0` for an empty collection.
            guard pageNumber < page.totalPages else { return items }
            pageNumber += 1
        }
    }
}

private extension HubRequest {
    /// `MAX_PAGE_SIZE` in the hub's `src/common/common.constants.ts` — `PaginationDto` rejects anything larger.
    static let maxPageSize = 50

    func paged(_ pageNumber: Int) -> Self {
        let paging = ["page": String(pageNumber), "pageSize": String(Self.maxPageSize)]
        return .init(
            method: method,
            path: path,
            query: query.merging(paging) { _, new in new },
            body: body,
            protected: protected
        )
    }
}
