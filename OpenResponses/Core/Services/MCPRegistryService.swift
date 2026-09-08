import Foundation

/// The public registry is a discovery source, not a security or provider-endorsement guarantee.
/// Only remote HTTPS endpoints usable by an iPhone are offered; no local packages are executed.
enum MCPRegistryService {
    struct Page { let providers: [MCPProvider]; let nextCursor: String? }
    static func search(_ query: String, cursor: String? = nil) async throws -> Page {
        var components = URLComponents(string: "https://registry.modelcontextprotocol.io/v0.1/servers")!
        components.queryItems = [URLQueryItem(name: "search", value: query), URLQueryItem(name: "limit", value: "100"), URLQueryItem(name: "version", value: "latest")]
        if let cursor { components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let reply = try await MCPAuthorizationTransport().send(request)
        guard reply.status == 200 else { throw MCPAuthorizationError.providerRejected(reply.status) }
        return try parse(reply.data)
    }

    static func parse(_ data: Data) throws -> Page {
        let json = try ResponseConfigurationValidation.object(String(decoding: data, as: UTF8.self), label: "Registry response")
        guard let entries = json["servers"] as? [[String: Any]] else { throw MCPAuthorizationError.invalidMetadata }
        var providers: [MCPProvider] = []
        var seen = Set<String>()
        for entry in entries {
            guard let server = entry["server"] as? [String: Any], let name = server["name"] as? String,
                  let remotes = server["remotes"] as? [[String: Any]] else { continue }
            let metadata = (entry["_meta"] as? [String: Any])?["io.modelcontextprotocol.registry/official"] as? [String: Any]
            guard metadata?["status"] as? String == "active", metadata?["isLatest"] as? Bool != false else { continue }
            for remote in remotes where ["streamable-http", "sse"].contains(remote["type"] as? String ?? "") {
                guard let url = remote["url"] as? String, !url.contains("{"), !url.contains("}"),
                      let safeURL = try? MCPOAuthSecurity.publicHTTPS(url),
                      !(URLComponents(url: safeURL, resolvingAgainstBaseURL: false)?.queryItems ?? []).contains(where: {
                          ["token", "key", "api_key", "apikey", "authorization", "password", "secret", "access_token"].contains($0.name.lowercased())
                      }), seen.insert(url).inserted else { continue }
                // Credential templates cannot be offered as a ready one-tap sign-in connection.
                let requiredHeaders = (remote["headers"] as? [[String: Any]] ?? []).contains { $0["isRequired"] as? Bool == true }
                providers.append(MCPProvider(id: "registry:" + name + ":" + url, name: String((server["title"] as? String ?? name).prefix(120)),
                    summary: String((server["description"] as? String ?? "Remote MCP server").prefix(500)), category: .development,
                    serverURL: url, signIn: requiredHeaders ? .providerSetup : .automatic,
                    documentationURL: server["websiteUrl"] as? String, registryName: name))
            }
        }
        return Page(providers: providers, nextCursor: (json["metadata"] as? [String: Any])?["nextCursor"] as? String)
    }
}
