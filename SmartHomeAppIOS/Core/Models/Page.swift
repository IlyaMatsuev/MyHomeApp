
struct Page<Item: Codable & Hashable>: Codable, Hashable {
    let items: [Item]
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let totalItems: Int
}
