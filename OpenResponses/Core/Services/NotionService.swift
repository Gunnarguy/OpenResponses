import Foundation

/// A comprehensive service for interacting with the Notion REST API.
/// Supports the latest API version (2025-09-03) with multi-source database handling.
final class NotionService {
    static let shared = NotionService()
    
    private let apiBaseURL = URL(string: "https://api.notion.com/v1/")!
    private let apiVersion = "2025-09-03"
    
    private var apiKey: String? {
        KeychainService.shared.load(forKey: "notionApiKey")
    }
    
    private init() {}
    
    enum NotionError: Error {
        case notConfigured
        case invalidURL
        case requestFailed(statusCode: Int, message: String)
        case invalidResponse
        case decodingFailed(Error)
        case missingDataSourceContext
        case multipleDataSources(names: [String])
        case dataSourceNotFound
        case emptyUpdatePayload
        case invalidPayload(String)
    }
    
    // MARK: - Search
    
    /// Performs a search across the user's Notion workspace.
    func search(query: String?, filterType: String? = nil, pageSize: Int? = nil, startCursor: String? = nil) async throws -> [String: Any] {
        let normalizedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedFilter = normalizeSearchFilter(filterType)

        AppLogger.log("🔍 [Notion] Starting search with query: \(normalizedQuery ?? "nil"), filter: \(normalizedFilter ?? "none")", category: .network, level: .info)
        
        var body: [String: Any] = [:]
        if let query = normalizedQuery, !query.isEmpty { body["query"] = query }
        if let filterType = normalizedFilter {
            body["filter"] = ["property": "object", "value": filterType]
        }
        if let pageSize = pageSize {
            body["page_size"] = max(1, min(pageSize, 100))
        }
        if let startCursor = startCursor?.trimmingCharacters(in: .whitespacesAndNewlines), !startCursor.isEmpty {
            body["start_cursor"] = startCursor
        }

        func finalize(_ data: Data, label: String) throws -> [String: Any] {
            let decoded = try decodeDictionary(from: data)
            let resultCount = (decoded["results"] as? [[String: Any]])?.count ?? 0
            AppLogger.log("✅ [Notion] \(label): found \(resultCount) results", category: .network, level: .info)
            return decoded
        }

        do {
            let data = try await performRequest(endpoint: "/search", method: "POST", body: body)
            return try finalize(data, label: "Search completed")
        } catch NotionError.requestFailed(let statusCode, let message) {
            // Legacy fallback when older Notion stacks reject the modern data_source filter.
            if statusCode == 400, normalizedFilter == "data_source" {
                AppLogger.log("⚠️ [Notion] Search filter 'data_source' rejected (HTTP 400). Retrying legacy 'database' filter for compatibility.", category: .network, level: .warning)
                var legacyBody = body
                legacyBody["filter"] = ["property": "object", "value": "database"]
                let data = try await performRequest(endpoint: "/search", method: "POST", body: legacyBody)
                return try finalize(data, label: "Legacy database search completed")
            }
            throw NotionError.requestFailed(statusCode: statusCode, message: message)
        }
    }
    
    /// Normalizes a search filter to Notion's supported values (`page` or `data_source`).
    func normalizeSearchFilter(_ rawFilter: String?) -> String? {
        guard let raw = rawFilter?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        switch raw.lowercased() {
        case "page", "pages":
            return "page"
        case "data_source", "data_sources", "database", "databases":
            return "data_source"
        default:
            AppLogger.log("⚠️ [Notion] Unsupported filter type '\(raw)'; defaulting to all objects", category: .network, level: .warning)
            return nil
        }
    }

    /// Produces a compact representation of the Notion search payload to keep responses small.
    func compactSearchResult(_ raw: [String: Any], maxResults: Int = 20, maxProperties: Int = 12, maxPreviewLength: Int = 160) -> [String: Any] {
        guard let resultArray = raw["results"] as? [[String: Any]] else { return raw }

        let slice = Array(resultArray.prefix(maxResults))
        var compactResults: [[String: Any]] = []
        compactResults.reserveCapacity(slice.count)

        for item in slice {
            guard let objectType = item["object"] as? String else { continue }
            var compact: [String: Any] = ["object": objectType]

            switch objectType {
            case "page":
                compact.merge(compactPage(item, maxProperties: maxProperties, maxPreviewLength: maxPreviewLength)) { $1 }
            case "database":
                compact.merge(compactDatabase(item, maxProperties: maxProperties, maxPreviewLength: maxPreviewLength)) { $1 }
            case "data_source":
                compact.merge(compactDataSource(item, maxPreviewLength: maxPreviewLength)) { $1 }
            default:
                compact.merge(compactUnknown(item, maxPreviewLength: maxPreviewLength)) { $1 }
            }

            compactResults.append(compact)
        }

        var finalResponse: [String: Any] = [:]
        finalResponse["object"] = raw["object"] ?? "list"
        if let type = raw["type"] { finalResponse["type"] = type }
        if let requestId = raw["request_id"] { finalResponse["request_id"] = requestId }
        if let nextCursor = raw["next_cursor"] { finalResponse["next_cursor"] = nextCursor }

        let rawHasMore = raw["has_more"] as? Bool ?? false
        finalResponse["has_more"] = rawHasMore || resultArray.count > maxResults
        finalResponse["results"] = compactResults
        if resultArray.count > maxResults {
            finalResponse["truncated"] = true
            finalResponse["results_in_batch"] = resultArray.count
        }

        return finalResponse
    }

    // MARK: - Compact Helpers

    private func compactPage(_ item: [String: Any], maxProperties: Int, maxPreviewLength: Int) -> [String: Any] {
        var compact: [String: Any] = [:]
        compact["id"] = item["id"]
        compact["url"] = item["url"]
        if let publicURL = item["public_url"] { compact["public_url"] = publicURL }
        compact["archived"] = item["archived"] ?? false
        compact["created_time"] = item["created_time"]
        compact["last_edited_time"] = item["last_edited_time"]
        if let parent = item["parent"] { compact["parent"] = parent }

        if let properties = item["properties"] as? [String: Any] {
            compact["title"] = extractTitle(from: properties)
            compact["properties"] = summarizeProperties(properties, maxCount: maxProperties, maxPreviewLength: maxPreviewLength)
        }

        return compact
    }

    private func compactDatabase(_ item: [String: Any], maxProperties: Int, maxPreviewLength: Int) -> [String: Any] {
        var compact: [String: Any] = [:]
        compact["id"] = item["id"]
        compact["url"] = item["url"]
        compact["archived"] = item["archived"] ?? false
        compact["created_time"] = item["created_time"]
        compact["last_edited_time"] = item["last_edited_time"]
        if let parent = item["parent"] { compact["parent"] = parent }
        if let titleArray = item["title"] as? [[String: Any]] {
            compact["title"] = concatenatePlainText(from: titleArray)
        }
        if let dataSources = item["data_sources"] as? [[String: Any]], !dataSources.isEmpty {
            compact["data_sources"] = dataSources.map { source in
                [
                    "id": source["id"] ?? "",
                    "name": (source["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                ]
            }
        }
        if let properties = item["properties"] as? [String: Any] {
            compact["properties"] = summarizeDatabaseProperties(properties, maxCount: maxProperties, maxPreviewLength: maxPreviewLength)
        }
        return compact
    }

    private func compactDataSource(_ item: [String: Any], maxPreviewLength: Int) -> [String: Any] {
        var compact: [String: Any] = [:]
        compact["id"] = item["id"]
        compact["name"] = (item["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let type = item["type"] { compact["type"] = type }
        if let parent = item["parent"] { compact["parent"] = parent }
        if let databaseParent = item["database_parent"] { compact["database_parent"] = databaseParent }
        if let properties = item["properties"] as? [String: Any] {
            compact["properties"] = summarizeDatabaseProperties(properties, maxCount: 24, maxPreviewLength: maxPreviewLength)
        }
        return compact
    }

    private func compactUnknown(_ item: [String: Any], maxPreviewLength: Int) -> [String: Any] {
        var compact: [String: Any] = [:]
        for key in ["id", "url", "name", "title", "type"] {
            if let value = item[key] { compact[key] = value }
        }
        if compact.isEmpty {
            compact["debug"] = truncate(String(describing: item), maxLength: maxPreviewLength)
        }
        return compact
    }

    private func summarizeProperties(_ properties: [String: Any], maxCount: Int, maxPreviewLength: Int) -> [String: Any] {
        let sortedKeys = properties.keys.sorted()
        let limitedKeys = sortedKeys.prefix(maxCount)
        var summaries: [String: Any] = [:]
        for key in limitedKeys {
            guard let property = properties[key] else { continue }
            if let summary = summarizePropertyValue(property, maxPreviewLength: maxPreviewLength) {
                summaries[key] = summary
            }
        }
        if properties.keys.count > maxCount {
            summaries["_truncated"] = true
        }
        return summaries
    }

    private func summarizeDatabaseProperties(_ properties: [String: Any], maxCount: Int, maxPreviewLength: Int) -> [[String: Any]] {
        let sortedKeys = properties.keys.sorted()
        let limitedKeys = sortedKeys.prefix(maxCount)
        var summaries: [[String: Any]] = []
        for key in limitedKeys {
            guard let property = properties[key] as? [String: Any] else { continue }
            let type = property["type"] as? String ?? "unknown"
            var entry: [String: Any] = [
                "name": key,
                "type": type
            ]
            if let summary = summarizePropertyValue(property, maxPreviewLength: maxPreviewLength)?["summary"] as? String, !summary.isEmpty {
                entry["example"] = summary
            }
            summaries.append(entry)
        }
        if properties.keys.count > maxCount {
            summaries.append(["_truncated": true])
        }
        return summaries
    }

    private func summarizePropertyValue(_ property: Any, maxPreviewLength: Int) -> [String: Any]? {
        guard let propertyDict = property as? [String: Any] else { return nil }
        let type = propertyDict["type"] as? String ?? "unknown"
        var summary = ""

        switch type {
        case "title":
            if let items = propertyDict["title"] as? [[String: Any]] {
                summary = concatenatePlainText(from: items)
            }
        case "rich_text":
            if let items = propertyDict["rich_text"] as? [[String: Any]] {
                summary = concatenatePlainText(from: items)
            }
        case "select":
            if let select = propertyDict["select"] as? [String: Any] {
                summary = (select["name"] as? String) ?? ""
            }
        case "multi_select":
            if let items = propertyDict["multi_select"] as? [[String: Any]] {
                summary = items.compactMap { $0["name"] as? String }.joined(separator: ", ")
            }
        case "status":
            if let status = propertyDict["status"] as? [String: Any] {
                summary = (status["name"] as? String) ?? ""
            }
        case "date":
            if let date = propertyDict["date"] as? [String: Any] {
                let start = date["start"] as? String ?? ""
                let end = date["end"] as? String
                summary = end != nil ? "\(start) -> \(end!)" : start
            }
        case "checkbox":
            summary = (propertyDict["checkbox"] as? Bool ?? false) ? "true" : "false"
        case "number":
            if let number = propertyDict["number"] { summary = String(describing: number) }
        case "url":
            summary = propertyDict["url"] as? String ?? ""
        case "email":
            summary = propertyDict["email"] as? String ?? ""
        case "phone_number":
            summary = propertyDict["phone_number"] as? String ?? ""
        case "people":
            if let people = propertyDict["people"] as? [[String: Any]] {
                summary = "\(people.count) people"
            }
        case "files":
            if let files = propertyDict["files"] as? [[String: Any]] {
                summary = "\(files.count) file(s)"
            }
        case "relation":
            if let relations = propertyDict["relation"] as? [[String: Any]] {
                summary = "\(relations.count) relation(s)"
            }
        case "rollup":
            if let rollup = propertyDict["rollup"] as? [String: Any], let rollupType = rollup["type"] as? String {
                if let value = rollup[rollupType] {
                    summary = truncate(String(describing: value), maxLength: maxPreviewLength)
                }
            }
        case "formula":
            if let formula = propertyDict["formula"] as? [String: Any], let formulaType = formula["type"] as? String, let value = formula[formulaType] {
                summary = truncate(String(describing: value), maxLength: maxPreviewLength)
            }
        default:
            break
        }

        if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            summary = truncate(String(describing: propertyDict[type] ?? propertyDict), maxLength: maxPreviewLength)
        }

        summary = truncate(summary, maxLength: maxPreviewLength)
        return [
            "type": type,
            "summary": summary
        ]
    }

    private func extractTitle(from properties: [String: Any]) -> String? {
        for (_, value) in properties {
            guard let property = value as? [String: Any], let type = property["type"] as? String, type == "title" else { continue }
            if let items = property["title"] as? [[String: Any]] {
                let title = concatenatePlainText(from: items)
                if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return title
                }
            }
        }
        return nil
    }

    private func concatenatePlainText(from items: [[String: Any]]) -> String {
        let concatenated = items.compactMap { $0["plain_text"] as? String }.joined()
        return concatenated.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func truncate(_ string: String, maxLength: Int) -> String {
        guard string.count > maxLength else { return string }
        let index = string.index(string.startIndex, offsetBy: maxLength)
        return String(string[string.startIndex..<index]) + "..."
    }

    // MARK: - Database
    
    /// Retrieves a specific database from Notion (returns data_sources array).
    func getDatabase(databaseId: String) async throws -> [String: Any] {
        AppLogger.log("📊 [Notion] Fetching database: \(databaseId)", category: .network, level: .info)
        let data = try await performRequest(endpoint: "databases/\(databaseId)", method: "GET")
        let result = try decodeDictionary(from: data)
        
        let dataSourceCount = (result["data_sources"] as? [Any])?.count ?? 0
        AppLogger.log("✅ [Notion] Database fetched: \(dataSourceCount) data source(s)", category: .network, level: .info)
        
        return result
    }
    
    // MARK: - Data Source
    
    /// Retrieves a specific data source from Notion (returns schema/properties).
    func getDataSource(dataSourceId: String) async throws -> [String: Any] {
        AppLogger.log("📋 [Notion] Fetching data source: \(dataSourceId)", category: .network, level: .info)
        let data = try await performRequest(endpoint: "data_sources/\(dataSourceId)", method: "GET")
        let result = try decodeDictionary(from: data)
        
        let propertyCount = (result["properties"] as? [String: Any])?.count ?? 0
        AppLogger.log("✅ [Notion] Data source fetched: \(propertyCount) properties", category: .network, level: .info)
        
        return result
    }
    
    // MARK: - Page Operations
    
    /// Creates a new page in a Notion data source.
    /// - Parameters:
    ///   - dataSourceId: The ID of the data source (if known).
    ///   - databaseId: The ID of the database (will resolve to a data source if needed).
    ///   - dataSourceName: Optional name to disambiguate if multiple data sources exist.
    ///   - properties: Page properties matching the data source schema.
    ///   - children: Optional array of block objects to include as page content.
    func createPage(
        dataSourceId: String? = nil,
        databaseId: String? = nil,
        dataSourceName: String? = nil,
        properties: [String: Any]? = nil,
        children: [[String: Any]]? = nil
    ) async throws -> [String: Any] {
        let trimmedDatabaseId = databaseId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let context = try await resolveDataSourceContext(
            dataSourceId: dataSourceId,
            databaseId: trimmedDatabaseId,
            dataSourceName: dataSourceName
        )

        AppLogger.log("➕ [Notion] Creating page in data source: \(context.dataSourceId)", category: .network, level: .info)

        var primaryBody: [String: Any] = [
            "parent": [
                "type": "data_source_id",
                "data_source_id": context.dataSourceId
            ]
        ]

        if let properties = properties, !properties.isEmpty {
            primaryBody["properties"] = properties
        }
        if let children = children, !children.isEmpty {
            primaryBody["children"] = children
        }

        var legacyBody: [String: Any]? = nil
        if let fallbackDatabaseId = trimmedDatabaseId ?? context.databaseId {
            var alternativeBody = primaryBody
            alternativeBody["parent"] = [
                "type": "database_id",
                "database_id": fallbackDatabaseId
            ]
            legacyBody = alternativeBody
        }

        func executeCreate(body: [String: Any]) async throws -> [String: Any] {
            let data = try await performRequest(endpoint: "/pages", method: "POST", body: body)
            let result = try decodeDictionary(from: data)
            let pageId = result["id"] as? String ?? "unknown"
            AppLogger.log("✅ [Notion] Page created: \(pageId)", category: .network, level: .info)
            return result
        }

        do {
            return try await executeCreate(body: primaryBody)
        } catch NotionError.requestFailed(let statusCode, let message) {
            guard statusCode == 400, let legacyBody else {
                throw NotionError.requestFailed(statusCode: statusCode, message: message)
            }
            AppLogger.log("⚠️ [Notion] data_source_id parent rejected (400). Retrying with database_id for compatibility.", category: .network, level: .warning)
            return try await executeCreate(body: legacyBody)
        }
    }
    
    /// Updates properties or archives an existing page.
    func updatePage(pageId: String, properties: [String: Any]? = nil, archived: Bool? = nil) async throws -> [String: Any] {
        AppLogger.log("✏️ [Notion] Updating page: \(pageId)", category: .network, level: .info)
        
        var body: [String: Any] = [:]
        
        if let properties = properties, !properties.isEmpty {
            body["properties"] = properties
        }
        if let archived = archived {
            body["archived"] = archived
        }
        
        guard !body.isEmpty else {
            throw NotionError.emptyUpdatePayload
        }
        
        let data = try await performRequest(endpoint: "/pages/\(pageId)", method: "PATCH", body: body)
        let result = try decodeDictionary(from: data)
        
        AppLogger.log("✅ [Notion] Page updated successfully", category: .network, level: .info)
        
        return result
    }
    
    /// Appends blocks (content) to a page.
    func appendBlocks(pageId: String, blocks: [[String: Any]]) async throws -> [String: Any] {
        AppLogger.log("📝 [Notion] Appending \(blocks.count) blocks to page: \(pageId)", category: .network, level: .info)
        
        let body: [String: Any] = [
            "children": blocks
        ]
        
        let data = try await performRequest(endpoint: "/blocks/\(pageId)/children", method: "PATCH", body: body)
        let result = try decodeDictionary(from: data)
        
        AppLogger.log("✅ [Notion] Blocks appended successfully", category: .network, level: .info)
        
        return result
    }
    
    /// Archives (soft-deletes) a page.
    func archivePage(pageId: String) async throws -> [String: Any] {
        try await updatePage(pageId: pageId, properties: nil, archived: true)
    }
    
    // MARK: - Utilities
    
    /// Converts a dictionary or JSON object to a pretty-printed JSON string.
    func prettyJSONString(from object: Any) throws -> String {
        if let string = object as? String { return string }
        guard JSONSerialization.isValidJSONObject(object) else {
            throw NotionError.invalidPayload("Unable to encode JSON output")
        }
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
    
    // MARK: - Private Helpers
    
    /// Resolves a data source ID from the given parameters.
    /// If dataSourceId is provided, returns it directly.
    /// If databaseId is provided, fetches the database and resolves to a single data source (or uses dataSourceName to disambiguate).
    private struct DataSourceContext {
        let dataSourceId: String
        let databaseId: String?
    }

    private func resolveDataSourceContext(
        dataSourceId: String?,
        databaseId: String?,
        dataSourceName: String?
    ) async throws -> DataSourceContext {
        if let id = dataSourceId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            if let databaseId = databaseId?.trimmingCharacters(in: .whitespacesAndNewlines), !databaseId.isEmpty {
                return DataSourceContext(dataSourceId: id, databaseId: databaseId)
            }

            // Attempt to infer parent database from the data source when not provided.
            if let dataSource = try? await getDataSource(dataSourceId: id),
               let databaseParent = dataSource["database_parent"] as? [String: Any],
               let inferredDatabaseId = databaseParent["database_id"] as? String,
               !inferredDatabaseId.isEmpty {
                return DataSourceContext(dataSourceId: id, databaseId: inferredDatabaseId)
            }

            return DataSourceContext(dataSourceId: id, databaseId: nil)
        }
        
        guard let databaseId = databaseId?.trimmingCharacters(in: .whitespacesAndNewlines), !databaseId.isEmpty else {
            throw NotionError.missingDataSourceContext
        }
        
        let database = try await getDatabase(databaseId: databaseId)
        guard let dataSources = database["data_sources"] as? [[String: Any]], !dataSources.isEmpty else {
            throw NotionError.dataSourceNotFound
        }
        
        // If a name is provided, try to match it
        if let name = dataSourceName?.lowercased() {
            if let matching = dataSources.first(where: { ($0["name"] as? String)?.lowercased() == name }),
               let id = matching["id"] as? String {
                return DataSourceContext(dataSourceId: id, databaseId: databaseId)
            }
        }
        
        // If there's only one data source, return it
        if dataSources.count == 1, let id = dataSources.first?["id"] as? String {
            return DataSourceContext(dataSourceId: id, databaseId: databaseId)
        }
        
        // Multiple data sources and no name provided
        let names = dataSources.compactMap { $0["name"] as? String }
        throw NotionError.multipleDataSources(names: names)
    }
    
    /// Performs a generic HTTP request to the Notion API.
    private func performRequest(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> Data {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            AppLogger.log("❌ [Notion] API key not configured", category: .network, level: .error)
            throw NotionError.notConfigured
        }
        
        let normalizedEndpoint: String
        if endpoint.hasPrefix("/") {
            normalizedEndpoint = String(endpoint.drop(while: { $0 == "/" }))
        } else {
            normalizedEndpoint = endpoint
        }
        
        guard let url = URL(string: normalizedEndpoint, relativeTo: apiBaseURL) else {
            AppLogger.log("❌ [Notion] Invalid URL for endpoint: \(endpoint)", category: .network, level: .error)
            throw NotionError.invalidURL
        }
        
        AppLogger.log("🌐 [Notion] \(method) \(url.absoluteString)", category: .network, level: .debug)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiVersion, forHTTPHeaderField: "Notion-Version")
        
        if let body = body {
            guard JSONSerialization.isValidJSONObject(body) else {
                AppLogger.log("❌ [Notion] Invalid JSON body", category: .network, level: .error)
                throw NotionError.invalidPayload("Request body contains non-JSON types")
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                AppLogger.log("📤 [Notion] Request body: \(bodyString)", category: .network, level: .debug)
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.log("❌ [Notion] Invalid response type", category: .network, level: .error)
            throw NotionError.invalidResponse
        }
        
        AppLogger.log("📥 [Notion] Response status: \(httpResponse.statusCode)", category: .network, level: .debug)
        
        if let responseString = String(data: data, encoding: .utf8) {
            AppLogger.log("📥 [Notion] Response body: \(responseString.prefix(500))...", category: .network, level: .debug)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            AppLogger.log("❌ [Notion] Request failed (\(httpResponse.statusCode)): \(message)", category: .network, level: .error)
            throw NotionError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }
        
        return data
    }
    
    /// Decodes a Data object into a dictionary.
    private func decodeDictionary(from data: Data) throws -> [String: Any] {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NotionError.invalidResponse
            }
            return json
        } catch let error as NotionError {
            throw error
        } catch {
            throw NotionError.decodingFailed(error)
        }
    }
}

// MARK: - Error Localization

extension NotionService.NotionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Notion API token is not configured."
        case .invalidURL:
            return "Failed to build a valid Notion API URL."
        case let .requestFailed(statusCode, message):
            return "Notion API request failed (HTTP \(statusCode)): \(message)"
        case .invalidResponse:
            return "Received an invalid response from the Notion API."
        case let .decodingFailed(error):
            return "Failed to decode Notion response: \(error.localizedDescription)"
        case .missingDataSourceContext:
            return "Provide a data_source_id or database_id to identify the destination data source."
        case let .multipleDataSources(names):
            let list = names.joined(separator: ", ")
            return "Multiple data sources found. Specify data_source_id or data_source_name. Available: \(list)"
        case .dataSourceNotFound:
            return "The requested database does not contain any data sources."
        case .emptyUpdatePayload:
            return "Provide properties or archived flag to update the page."
        case let .invalidPayload(message):
            return message
        }
    }
}
