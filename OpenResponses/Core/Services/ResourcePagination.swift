import Foundation

struct ResourcePage<Item: Decodable>: Decodable {
    let data: [Item]
    let hasMore: Bool
    let lastId: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case lastId = "last_id"
    }
}

enum ResourcePagination {
    /// Never silently returns an incomplete list if the server stops advancing its cursor.
    static func collect<Item: Decodable & Identifiable>(
        maxPages: Int = 1_000,
        fetch: (String?) async throws -> ResourcePage<Item>
    ) async throws -> [Item] where Item.ID == String {
        var cursor: String?
        var cursors = Set<String>()
        var ids = Set<String>()
        var items: [Item] = []
        for _ in 0..<maxPages {
            try Task.checkCancellation()
            let page = try await fetch(cursor)
            items.append(contentsOf: page.data.filter { ids.insert($0.id).inserted })
            if !page.hasMore { return items }
            guard let next = page.lastId ?? page.data.last?.id, !next.isEmpty,
                  cursors.insert(next).inserted else {
                throw OpenAIServiceError.invalidRequest("The server returned a repeating or missing pagination cursor. Refresh to try again.")
            }
            cursor = next
        }
        throw OpenAIServiceError.invalidRequest("The resource list exceeded the page limit. Narrow the request and try again.")
    }

    static func list<Item: Decodable & Identifiable>(path: String, as type: Item.Type) async throws -> [Item] where Item.ID == String {
        try await collect { cursor in
            var components = URLComponents()
            components.path = path
            components.queryItems = [URLQueryItem(name: "limit", value: "100")]
            if let cursor { components.queryItems?.append(URLQueryItem(name: "after", value: cursor)) }
            guard let endpoint = components.string else { throw OpenAIServiceError.invalidResponseData }
            var request = try ResponsesAPIClient().request(path: endpoint, method: "GET")
            request.timeoutInterval = 30
            let (data, response) = try await URLSession.shared.data(for: request)
            try ResponsesAPIClient.validate(response, data: data)
            return try JSONDecoder().decode(ResourcePage<Item>.self, from: data)
        }
    }
}
