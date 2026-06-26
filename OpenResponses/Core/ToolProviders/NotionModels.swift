import Foundation

// MARK: - Public Models

public struct NotionDatabaseSummary: nonisolated Codable, Identifiable, nonisolated Hashable, nonisolated Equatable, Sendable {
    public var id: String { // Notion can return non-UUIDs for child_database blocks
        return notionId
    }

    let notionId: String
    let title: String
    let parentPageId: String?
    let source: String

    nonisolated public static func == (lhs: NotionDatabaseSummary, rhs: NotionDatabaseSummary) -> Bool {
        return lhs.notionId == rhs.notionId && lhs.title == rhs.title && lhs.parentPageId == rhs.parentPageId && lhs.source == rhs.source
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(notionId)
        hasher.combine(title)
        hasher.combine(parentPageId)
        hasher.combine(source)
    }
}

public struct NotionPageSummary: nonisolated Hashable, nonisolated Codable, Identifiable, Sendable {
    public var id: String { notionId }
    let notionId: String
    let title: String
}

// MARK: - Internal Models

struct NotionSearchReq: nonisolated Codable, Sendable {
    struct Filter: nonisolated Codable, Sendable { let property: String; let value: String }
    let query: String?
    let filter: Filter?
    let startCursor: String?
    let pageSize: Int?

    enum CodingKeys: String, CodingKey {
        case query, filter
        case startCursor = "start_cursor"
        case pageSize = "page_size"
    }
}

struct NotionSearchResp: nonisolated Codable, Sendable {
    let results: [NotionObject]
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

enum NotionObject: nonisolated Codable, Sendable {
    case database(NotionDatabase)
    case page(NotionPageWithParent)
    case block(NotionBlock)
    case dataSource(NotionDataSourceSearchResult)
    case unknown

    enum CodingKeys: String, CodingKey { case object }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = (try? container.decode(String.self, forKey: .object)) ?? ""
        let singleValueContainer = try decoder.singleValueContainer()
        switch type {
        case "database": self = try .database(singleValueContainer.decode(NotionDatabase.self))
        case "page": self = try .page(singleValueContainer.decode(NotionPageWithParent.self))
        case "block": self = try .block(singleValueContainer.decode(NotionBlock.self))
        case "data_source": self = try .dataSource(singleValueContainer.decode(NotionDataSourceSearchResult.self))
        default: self = .unknown
        }
    }

    nonisolated func encode(to _: Encoder) throws {
        // Not needed for this implementation
    }
}

struct NotionPageWithParent: nonisolated Codable, Sendable {
    struct Parent: nonisolated Codable, Sendable {
        let type: String?
        let databaseId: String?
        let dataSourceId: String?

        enum CodingKeys: String, CodingKey {
            case type
            case databaseId = "database_id"
            case dataSourceId = "data_source_id"
        }
    }

    let object: String
    let id: String
    let parent: Parent?
}

struct NotionDataSource: nonisolated Codable, Sendable {
    let id: String
    let name: String?
}

struct NotionDataSourceSearchResult: nonisolated Codable, Sendable {
    struct Parent: nonisolated Codable, Sendable {
        let type: String?
        let databaseId: String?
        let pageId: String?

        enum CodingKeys: String, CodingKey {
            case type
            case databaseId = "database_id"
            case pageId = "page_id"
        }
    }

    let object: String
    let id: String
    let name: String?
    let parent: Parent?
    let databaseParent: Parent?

    enum CodingKeys: String, CodingKey {
        case object, id, name, parent
        case databaseParent = "database_parent"
    }

    nonisolated var databaseId: String? {
        parent?.databaseId ?? databaseParent?.databaseId
    }
}

struct NotionDatabase: nonisolated Codable, Sendable {
    struct Parent: nonisolated Codable, Sendable {
        let type: String?
        let pageId: String?
        let workspace: Bool?

        enum CodingKeys: String, CodingKey {
            case type, workspace
            case pageId = "page_id"
        }
    }

    struct Title: nonisolated Codable, Sendable {
        let plainText: String?

        enum CodingKeys: String, CodingKey {
            case plainText = "plain_text"
        }
    }

    let object: String
    let id: String
    let parent: Parent
    let title: [Title]
    let dataSources: [NotionDataSource]?

    enum CodingKeys: String, CodingKey {
        case object, id, parent, title
        case dataSources = "data_sources"
    }
}

struct NotionPage: nonisolated Codable, Sendable { let object: String; let id: String }

struct NotionBlock: nonisolated Codable, Sendable {
    let object: String; let id: String; let type: String
    let child_database: ChildDB?
    let link_to_database: LinkDB?
    struct ChildDB: nonisolated Codable, Sendable { let title: String }
    struct LinkDB: nonisolated Codable, Sendable {
        struct DB: nonisolated Codable, Sendable { let id: String? }
        let database: DB?
    }
}

struct NotionChildrenResp: nonisolated Codable, Sendable {
    let results: [NotionBlock]
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

struct NotionRichText: nonisolated Codable, Sendable {
    let plainText: String?

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}

struct NotionPropertyValue: nonisolated Codable, Sendable {
    let type: String?
    let title: [NotionRichText]?
}

struct NotionPageWithProps: nonisolated Codable, Sendable {
    let id: String
    let properties: [String: NotionPropertyValue]
}

struct NotionQueryResp: nonisolated Codable, Sendable {
    let results: [NotionPageWithProps]
    let hasMore: Bool
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case results
        case hasMore = "has_more"
        case nextCursor = "next_cursor"
    }
}

struct NotionPageParentResp: nonisolated Codable, Sendable {
    struct Parent: nonisolated Codable, Sendable {
        let type: String
        let databaseId: String?
        let pageId: String?

        enum CodingKeys: String, CodingKey {
            case type
            case databaseId = "database_id"
            case pageId = "page_id"
        }
    }

    let id: String
    let parent: Parent
}
