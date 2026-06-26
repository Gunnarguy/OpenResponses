@preconcurrency import Foundation

// MARK: - Notion Provider

/// NotionProvider: 100% compliant with Notion API version 2025-09-03
///
/// Key 2025-09-03 Changes:
/// - Databases now contain one or more `data_sources` (each with their own properties/schema)
/// - Search API returns "data_source" objects instead of "database" objects
/// - Query operations use `/v1/data_sources/{id}/query` instead of `/v1/databases/{id}/query`
/// - Creating pages requires `data_source_id` parent (not `database_id`)
/// - Relation properties now require `data_source_id` (not just `database_id`)
///
/// This provider:
/// ✅ Uses Notion-Version: 2025-09-03 header for all requests
/// ✅ Searches for both "database" and "data_source" objects
/// ✅ Extracts database IDs from page parents when databases aren't directly searchable
/// ✅ Uses `/v1/data_sources/{id}/query` for all query operations (with legacy fallback)
/// ✅ Fetches database metadata via GET /databases/{id} to discover data_sources array
/// ✅ Caches data_source resolution to minimize API calls
public actor NotionProvider: ToolProvider, NotionReadable {
    nonisolated public let kind: ToolKind = .notion
    nonisolated public let capabilities: ProviderCapability = [.listDatabases]

    nonisolated private let http = HttpClient()
    nonisolated private let base = URL(string: "https://api.notion.com/v1")!
    nonisolated private let version = "2025-09-03"
    /// Unified keychain key for Notion integration token - matches NotionConnectionView, SettingsHomeView, etc.
    nonisolated let tokenAccount = "notionApiKey"
    private var dsCache: [String: (id: String, name: String?)] = [:]

    public init() {}

    /// Search for databases across the entire workspace (top-level call from chat)
    /// Returns all databases accessible with the current integration token.
    ///
    /// API Version 2025-09-03 Compliance:
    /// - Searches for both "database" objects (direct database access) AND "data_source" objects (new 2025 model)
    /// - Extracts database_id from page parents when databases aren't directly searchable
    /// - Fetches database metadata via GET /databases/{id} to get data_sources array
    /// - Returns one result per database (not per data source) for cleaner UX
    public func searchDatabases(query: String? = nil) async throws -> [NotionDatabaseSummary] {
        var databases = Set<NotionDatabaseSummary>()
        var databaseIds = Set<String>()

        let normalizedQuery: String?
        if let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            normalizedQuery = trimmed
        } else {
            normalizedQuery = nil
        }

        // STRATEGY 1: Prefer the new data_source vocabulary, fallback to legacy database filter if necessary
        print("🔍 NotionProvider: Searching for data_source objects...")
        do {
            let before = databaseIds.count
            let filterUsed = try await collectSearchResults(
                query: normalizedQuery,
                filters: ["data_source", "database"],
                label: "data_source search"
            ) { obj in
                switch obj {
                case let .database(db):
                    if databaseIds.insert(db.id).inserted {
                        print("  - Found database via search: \(db.id)")
                    }
                case let .dataSource(ds):
                    if let dbId = ds.databaseId, databaseIds.insert(dbId).inserted {
                        let label = ds.name ?? "(unnamed data source)"
                        print("  - Found data_source \(label) -> database \(dbId)")
                    }
                default:
                    break
                }
            }
            let delta = databaseIds.count - before
            print("🔍 NotionProvider: data_source search added \(delta) database IDs (filter=\(filterUsed ?? "none"))")
        } catch let error as SearchHTTPError {
            print("⚠️ NotionProvider: data_source search failed: \(error)")
        } catch {
            print("⚠️ NotionProvider: data_source search failed: \(error)")
        }

        // STRATEGY 2: Search for database objects directly, falling back to unfiltered search when new vocab is mandatory
        print("🔍 NotionProvider: Searching for database objects...")
        do {
            let before = databases.count
            let filterUsed = try await collectSearchResults(
                query: normalizedQuery,
                filters: ["database", nil],
                label: "database search"
            ) { obj in
                switch obj {
                case let .database(db):
                    let title = db.title.first?.plainText ?? "(untitled)"
                    let summary = NotionDatabaseSummary(
                        notionId: db.id,
                        title: title,
                        parentPageId: db.parent.pageId,
                        source: "search"
                    )
                    if databases.insert(summary).inserted {
                        databaseIds.insert(db.id)
                        print("  - Found database: \(title) [\(db.id)]")
                    }
                case let .dataSource(ds):
                    if let dbId = ds.databaseId, databaseIds.insert(dbId).inserted {
                        print("  - Captured database ID via data_source fallback: \(dbId)")
                    }
                default:
                    break
                }
            }
            let delta = databases.count - before
            print("🔍 NotionProvider: database search added \(delta) databases (filter=\(filterUsed ?? "none"))")
        } catch let error as SearchHTTPError {
            print("⚠️ NotionProvider: database search failed: \(error)")
        } catch {
            print("⚠️ NotionProvider: database search failed: \(error)")
        }

        // STRATEGY 3: Extract database_id from page parents for any remaining databases
        print("🔍 NotionProvider: Searching pages to extract parent database IDs...")
        do {
            let before = databaseIds.count
            _ = try await collectSearchResults(
                query: normalizedQuery,
                filters: [nil],
                label: "page search"
            ) { obj in
                if case let .page(page) = obj, let dbId = page.parent?.databaseId, databaseIds.insert(dbId).inserted {
                    print("  - Found database via page parent: \(dbId)")
                }
            }
            let delta = databaseIds.count - before
            print("🔍 NotionProvider: Page search added \(delta) database IDs")
        } catch let error as SearchHTTPError {
            print("⚠️ NotionProvider: Page search failed: \(error)")
        } catch {
            print("⚠️ NotionProvider: Page search failed: \(error)")
        }

        // STRATEGY 4: Fetch full metadata for each database ID
        print("🔍 NotionProvider: Fetching metadata for \(databaseIds.count) databases...")
        let missingIds = databaseIds.filter { dbId in
            !databases.contains(where: { $0.notionId == dbId })
        }

        await withTaskGroup(of: NotionDatabaseSummary?.self) { group in
            for dbId in missingIds {
                group.addTask {
                    do {
                        let req = try self.baseRequest("databases/\(dbId)")
                        let (data, _, _) = try await self.http.send(req)
                        let db = try await MainActor.run { try JSONDecoder().decode(NotionDatabase.self, from: data) }
                        let title = db.title.first?.plainText ?? "(untitled)"

                        let summary = NotionDatabaseSummary(
                            notionId: db.id,
                            title: title,
                            parentPageId: db.parent.pageId,
                            source: "parent_id"
                        )

                        print("  ✅ Fetched database: \(title)")

                        if let dataSources = db.dataSources {
                            print("     └─ Has \(dataSources.count) data source(s)")
                            for ds in dataSources {
                                print("        - \(ds.name ?? "Unnamed") [\(ds.id)]")
                            }
                        }

                        return summary
                    } catch {
                        print("  ⚠️ Failed to fetch database \(dbId): \(error)")
                        return nil
                    }
                }
            }

            for await summary in group {
                if let summary = summary {
                    databases.insert(summary)
                }
            }
        }

        print("🔍 NotionProvider: Final result: \(databases.count) databases found")
        return Array(databases).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private struct SearchHTTPError: Error, CustomStringConvertible {
        let statusCode: Int
        let body: String
        let attemptedFilter: String?

        var description: String {
            let filterLabel = attemptedFilter ?? "none"
            let summary = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if summary.isEmpty {
                return "HTTP \(statusCode) for filter '\(filterLabel)': <empty body>"
            }
            let snippet = summary.count > 160 ? String(summary.prefix(160)) + "…" : summary
            return "HTTP \(statusCode) for filter '\(filterLabel)': \(snippet)"
        }
    }

    private func executeSearch(query: String?, filterValue: String?, cursor: String?) async throws -> NotionSearchResp {
        var payload: [String: Any] = ["page_size": 100]
        if let query {
            payload["query"] = query
        }
        if let cursor {
            payload["start_cursor"] = cursor
        }
        if let filterValue {
            payload["filter"] = ["property": "object", "value": filterValue]
        }

        let body = try JSONSerialization.data(withJSONObject: payload, options: [])
        let req = try baseRequest("search", method: "POST", jsonBody: body)
        let (data, response, _) = try await http.send(req)

        if let httpResponse = response as? HTTPURLResponse, !(200 ... 299).contains(httpResponse.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SearchHTTPError(statusCode: httpResponse.statusCode, body: message, attemptedFilter: filterValue)
        }

        return try JSONDecoder().decode(NotionSearchResp.self, from: data)
    }

    private func firstSearchPage(query: String?, filters: [String?], label: String) async throws -> (NotionSearchResp, String?) {
        var lastError: Error?

        for (index, filter) in filters.enumerated() {
            do {
                let response = try await executeSearch(query: query, filterValue: filter, cursor: nil)
                let filterLabel = filter ?? "none"
                print("🔍 NotionProvider: \(label) succeeded with filter '\(filterLabel)' (results: \(response.results.count))")
                return (response, filter)
            } catch let httpError as SearchHTTPError {
                let isLast = index == filters.count - 1
                if httpError.statusCode == 400 || httpError.statusCode == 422, !isLast {
                    let current = filter ?? "none"
                    let next = filters[index + 1] ?? "none"
                    print("⚠️ NotionProvider: filter '\(current)' rejected (HTTP \(httpError.statusCode)). Retrying with '\(next)'.")
                    lastError = httpError
                    continue
                }
                throw httpError
            } catch {
                lastError = error
                throw error
            }
        }

        if let error = lastError {
            throw error
        }

        let attemptedFilter = filters.last?.flatMap { $0 }
        throw SearchHTTPError(statusCode: -1, body: "All search filters failed", attemptedFilter: attemptedFilter)
    }

    private func collectSearchResults(
        query: String?,
        filters: [String?],
        label: String,
        onResult: (NotionObject) -> Void
    ) async throws -> String? {
        var (response, activeFilter) = try await firstSearchPage(query: query, filters: filters, label: label)

        while true {
            response.results.forEach(onResult)

            guard response.hasMore, let next = response.nextCursor else {
                break
            }

            response = try await executeSearch(query: query, filterValue: activeFilter, cursor: next)
        }

        return activeFilter
    }

    nonisolated private func baseRequest(_ path: String, method: String = "GET", jsonBody: Data? = nil) throws -> URLRequest {
        let url = base.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        guard let token = TokenStore.readString(account: tokenAccount) else {
            throw NSError(domain: "NotionProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Notion token for request."])
        }
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(version, forHTTPHeaderField: "Notion-Version")
        if jsonBody != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = jsonBody
        }
        return req
    }

    public func listDatabasesUnderPage(_ pageId: String) async throws -> [NotionDatabaseSummary] {
        var set = Set<NotionDatabaseSummary>()

        // Strategy: CHILDREN crawl -> child_database + link_to_database
        var cursorB: String? = nil
        var linkedDatabaseIds: Set<String> = []

        repeat {
            var path = "blocks/\(pageId)/children?page_size=100"
            if let c = cursorB { path += "&start_cursor=\(c)" }
            let req = try baseRequest(path)
            let (data, _, _) = try await http.send(req)
            let resp = try JSONDecoder().decode(NotionChildrenResp.self, from: data)
            for b in resp.results {
                switch b.type {
                case "child_database":
                    let t = b.child_database?.title ?? "(untitled)"
                    if !set.contains(where: { $0.title == t }) {
                        set.insert(.init(notionId: b.id, title: t, parentPageId: pageId, source: "children"))
                    }
                case "link_to_database":
                    if let dbId = b.link_to_database?.database?.id, !set.contains(where: { $0.notionId == dbId }) {
                        linkedDatabaseIds.insert(dbId)
                    }
                default: break
                }
            }
            cursorB = resp.hasMore ? resp.nextCursor : nil
        } while cursorB != nil

        if !linkedDatabaseIds.isEmpty {
            let fetchedLinkedDBs = try await withThrowingTaskGroup(of: NotionDatabaseSummary?.self) { group in
                for dbId in linkedDatabaseIds {
                    group.addTask {
                        let req2 = try self.baseRequest("databases/\(dbId)")
                        let (d2, _, _) = try await self.http.send(req2)
                        let resolved = try await MainActor.run { try JSONDecoder().decode(NotionDatabase.self, from: d2) }
                        let t = resolved.title.first?.plainText ?? "(untitled)"
                        return NotionDatabaseSummary(notionId: resolved.id, title: t, parentPageId: resolved.parent.pageId, source: "children")
                    }
                }
                var results: [NotionDatabaseSummary] = []
                for try await result in group {
                    if let result = result {
                        results.append(result)
                    }
                }
                return results
            }

            for db in fetchedLinkedDBs {
                set.insert(db)
            }
        }

        return Array(set).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Database Page Listing (client-only, API-exact)

    // Resolve data_source_id for a given database_id and memoize
    private func resolveDataSource(for databaseId: String) async throws -> (id: String, name: String?) {
        if let cached = dsCache[databaseId] { return cached }
        let req = try baseRequest("databases/\(databaseId)")
        let (data, _, _) = try await http.send(req)
        let resp = try JSONDecoder().decode(NotionDatabase.self, from: data)
        if let ds = resp.dataSources?.first {
            let result = (id: ds.id, name: ds.name)
            dsCache[databaseId] = result
            return result
        }
        throw NSError(domain: "NotionProvider", code: 422, userInfo: [NSLocalizedDescriptionKey: "No data_source found for database \(databaseId)"])
    }

    /// Returns pages (id + human title) for a given database, handling pagination.
    public func listPages(inDatabase databaseId: String, dataSourceId: String? = nil, pageSize: Int = 50) async throws -> [NotionPageSummary] {
        let dsId: String
        if let override = dataSourceId?.trimmingCharacters(in: .whitespacesAndNewlines), !override.isEmpty {
            dsId = override
        } else {
            dsId = try await resolveDataSource(for: databaseId).id
        }

        var acc: [NotionPageSummary] = []
        var cursor: String? = nil
        repeat {
            var payload: [String: Any] = ["page_size": pageSize]
            if let c = cursor { payload["start_cursor"] = c }
            let body = try JSONSerialization.data(withJSONObject: payload, options: [])
            let req = try baseRequest("data_sources/\(dsId)/query", method: "POST", jsonBody: body)
            do {
                let (data, _, _) = try await http.send(req)
                let resp = try JSONDecoder().decode(NotionQueryResp.self, from: data)
                acc += resp.results.map { page in
                    NotionPageSummary(notionId: page.id, title: extractTitle(from: page))
                }
                cursor = resp.hasMore ? resp.nextCursor : nil
            } catch {
                // Fallback: if data_sources query is unavailable, use legacy database query endpoint
                return try await legacyListPages(inDatabase: databaseId, pageSize: pageSize)
            }
        } while cursor != nil
        return acc
    }

    /// Returns pages whose title property equals the provided value (defaults to "Project Name").
    public func findPages(inDatabase databaseId: String, dataSourceId: String? = nil, titleProperty: String = "Project Name", equals value: String, pageSize: Int = 10) async throws -> [NotionPageSummary] {
        let dsId: String
        if let override = dataSourceId?.trimmingCharacters(in: .whitespacesAndNewlines), !override.isEmpty {
            dsId = override
        } else {
            dsId = try await resolveDataSource(for: databaseId).id
        }

        let filter: [String: Any] = [
            "filter": [
                "property": titleProperty,
                "title": ["equals": value],
            ],
            "page_size": pageSize,
        ]
        let body = try JSONSerialization.data(withJSONObject: filter, options: [])
        let req = try baseRequest("data_sources/\(dsId)/query", method: "POST", jsonBody: body)
        do {
            let (data, _, _) = try await http.send(req)
            let resp = try JSONDecoder().decode(NotionQueryResp.self, from: data)
            return resp.results.map { NotionPageSummary(notionId: $0.id, title: extractTitle(from: $0)) }
        } catch {
            // Fallback: if data_sources query is unavailable, use legacy database query endpoint
            return try await legacyFindPages(inDatabase: databaseId, titleProperty: titleProperty, equals: value, pageSize: pageSize)
        }
    }

    /// For a given page, returns its parent database_id (if any).
    public func parentDatabaseId(ofPageId pageId: String) async throws -> String? {
        let req = try baseRequest("pages/\(pageId)")
        let (data, _, _) = try await http.send(req)
        let resp = try JSONDecoder().decode(NotionPageParentResp.self, from: data)
        return resp.parent.databaseId
    }

    // MARK: - Helpers

    private func extractTitle(from page: NotionPageWithProps) -> String {
        // Prefer "Project Name", then "Name", else first title property
        if let s = page.properties["Project Name"]?.title?.first?.plainText, !s.isEmpty {
            return s
        }
        if let s = page.properties["Name"]?.title?.first?.plainText, !s.isEmpty {
            return s
        }
        if let any = page.properties.values.first(where: { ($0.title?.isEmpty == false) }),
           let s = any.title?.first?.plainText, !s.isEmpty
        {
            return s
        }
        return "(untitled)"
    }

    // Fallbacks for compatibility with environments where data_sources is not yet available or returns non-standard errors.
    private func legacyListPages(inDatabase databaseId: String, pageSize: Int) async throws -> [NotionPageSummary] {
        var acc: [NotionPageSummary] = []
        var cursor: String? = nil
        repeat {
            var payload: [String: Any] = ["page_size": pageSize]
            if let c = cursor { payload["start_cursor"] = c }
            let body = try JSONSerialization.data(withJSONObject: payload, options: [])
            let req = try baseRequest("databases/\(databaseId)/query", method: "POST", jsonBody: body)
            let (data, _, _) = try await http.send(req)
            let resp = try JSONDecoder().decode(NotionQueryResp.self, from: data)
            acc += resp.results.map { NotionPageSummary(notionId: $0.id, title: extractTitle(from: $0)) }
            cursor = resp.hasMore ? resp.nextCursor : nil
        } while cursor != nil
        return acc
    }

    private func legacyFindPages(inDatabase databaseId: String, titleProperty: String, equals value: String, pageSize: Int) async throws -> [NotionPageSummary] {
        let filter: [String: Any] = [
            "filter": [
                "property": titleProperty,
                "title": ["equals": value],
            ],
            "page_size": pageSize,
        ]
        let body = try JSONSerialization.data(withJSONObject: filter, options: [])
        let req = try baseRequest("databases/\(databaseId)/query", method: "POST", jsonBody: body)
        let (data, _, _) = try await http.send(req)
        let resp = try JSONDecoder().decode(NotionQueryResp.self, from: data)
        return resp.results.map { NotionPageSummary(notionId: $0.id, title: extractTitle(from: $0)) }
    }
}
