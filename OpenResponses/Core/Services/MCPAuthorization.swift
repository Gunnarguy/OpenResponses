import Foundation
import CryptoKit
import Security

nonisolated enum MCPAuthorizationError: LocalizedError, Equatable {
    case unsafeURL, invalidMetadata, unsupportedSignIn, providerRegistrationRequired
    case invalidCallback, cancelled, expired, secureStorage, responseTooLarge
    case providerRejected(Int)
    var errorDescription: String? {
        switch self {
        case .unsafeURL: return "Use a public HTTPS server address without embedded credentials."
        case .invalidMetadata: return "The provider returned inconsistent sign-in information. Sign-in could not be verified."
        case .unsupportedSignIn: return "This server does not advertise supported secure account sign-in. Check its connection instructions."
        case .providerRegistrationRequired: return "This provider requires approval or app registration before OpenResponses can offer sign-in."
        case .invalidCallback: return "The sign-in response did not match this connection attempt. Please connect again."
        case .cancelled: return "Sign-in was cancelled."
        case .expired: return "Your connection has expired. Sign in again to reconnect."
        case .secureStorage: return "The connection could not be saved securely. Unlock your device and try again."
        case .responseTooLarge: return "The provider returned an oversized sign-in response."
        case .providerRejected(let status): return "The provider could not complete sign-in (HTTP \(status)). Try again or check your account access."
        }
    }
}

nonisolated enum MCPOAuthSecurity {
    static let redirectURI = "openresponses://mcp/oauth/callback"

    static func publicHTTPS(_ text: String) throws -> URL {
        guard let c = URLComponents(string: text), c.scheme?.lowercased() == "https",
              let host = c.host?.lowercased(), !host.isEmpty, c.user == nil, c.password == nil,
              host.contains("."),
              c.fragment == nil, c.port == nil || c.port == 443,
              host != "localhost", !host.hasSuffix(".localhost"), !host.hasSuffix(".local"),
              !host.contains(":"), host.range(of: "^[0-9.]+$", options: .regularExpression) == nil,
              let url = c.url else { throw MCPAuthorizationError.unsafeURL }
        return url
    }

    static func random() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { throw MCPAuthorizationError.secureStorage }
        return base64URL(Data(bytes))
    }
    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    static func challenge(_ verifier: String) -> String { base64URL(Data(SHA256.hash(data: Data(verifier.utf8)))) }

    static func resourceMatches(_ resource: URL, server: URL) -> Bool {
        let resourcePath = resource.path.isEmpty ? "/" : resource.path
        let serverPath = server.path.isEmpty ? "/" : server.path
        return resource.host?.lowercased() == server.host?.lowercased() &&
            (serverPath == resourcePath || serverPath.hasPrefix(resourcePath.hasSuffix("/") ? resourcePath : resourcePath + "/"))
    }

    static func callbackCode(_ url: URL, state: String, issuer: String) throws -> String {
        guard let expected = URLComponents(string: redirectURI), let actual = URLComponents(url: url, resolvingAgainstBaseURL: false),
              actual.scheme == expected.scheme, actual.host == expected.host, actual.path == expected.path,
              actual.port == nil, actual.user == nil, actual.password == nil, actual.fragment == nil else { throw MCPAuthorizationError.invalidCallback }
        let items = actual.queryItems ?? []
        func single(_ name: String) throws -> String? {
            let values = items.filter { $0.name == name }
            guard values.count <= 1 else { throw MCPAuthorizationError.invalidCallback }
            return values.first?.value
        }
        guard try single("state") == state else { throw MCPAuthorizationError.invalidCallback }
        if let receivedIssuer = try single("iss"), receivedIssuer != issuer { throw MCPAuthorizationError.invalidCallback }
        if try single("error") != nil { throw MCPAuthorizationError.cancelled }
        guard let code = try single("code"), !code.isEmpty else { throw MCPAuthorizationError.invalidCallback }
        return code
    }

    static func form(_ values: [String: String]) -> Data {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return Data(values.sorted { $0.key < $1.key }.map {
            "\($0.key.addingPercentEncoding(withAllowedCharacters: allowed)!)=\($0.value.addingPercentEncoding(withAllowedCharacters: allowed)!)"
        }.joined(separator: "&").utf8)
    }
}

nonisolated struct MCPOAuthMetadata: Codable, Equatable, Sendable {
    let issuer: String
    let authorizationEndpoint: String
    let tokenEndpoint: String
    let registrationEndpoint: String?
    let revocationEndpoint: String?
    let resource: String
    let scopes: [String]
    let authMethod: String
}

nonisolated struct MCPOAuthClient: Codable, Equatable, Sendable {
    let id: String
    let secret: String?
    let authMethod: String
}

nonisolated struct MCPOAuthCredential: Codable, Equatable, Sendable {
    let metadata: MCPOAuthMetadata
    let client: MCPOAuthClient
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
    let scope: String?
    func needsRefresh(at date: Date = Date()) -> Bool { expiresAt.map { $0 <= date.addingTimeInterval(90) } ?? false }
}

/// Redirects are deliberately refused: token POST bodies must never be replayed to a new URL.
nonisolated final class MCPAuthorizationTransport: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    struct Reply: Sendable { let status: Int; let data: Data; let authenticate: String? }
    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    func send(_ request: URLRequest) async throws -> Reply {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw MCPAuthorizationError.invalidMetadata }
        var data = Data()
        for try await byte in bytes {
            try Task.checkCancellation()
            guard data.count < 1_048_576 else { throw MCPAuthorizationError.responseTooLarge }
            data.append(byte)
        }
        return Reply(status: http.statusCode, data: data, authenticate: http.value(forHTTPHeaderField: "WWW-Authenticate"))
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) { completionHandler(nil) }
}

@MainActor
final class MCPAuthorizationClient {
    typealias Send = (URLRequest) async throws -> MCPAuthorizationTransport.Reply
    private let send: Send
    init(send: @escaping Send = { try await MCPAuthorizationTransport().send($0) }) { self.send = send }

    private func request(_ url: String, method: String = "GET", data: Data? = nil, contentType: String = "application/json") throws -> URLRequest {
        var request = URLRequest(url: try MCPOAuthSecurity.publicHTTPS(url))
        request.httpMethod = method
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("OpenResponses/2.6", forHTTPHeaderField: "User-Agent")
        if data != nil { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        return request
    }

    private func json(_ reply: MCPAuthorizationTransport.Reply) throws -> [String: Any] {
        guard let object = try? JSONSerialization.jsonObject(with: reply.data) as? [String: Any] else { throw MCPAuthorizationError.invalidMetadata }
        return object
    }

    func discover(serverURL: String) async throws -> MCPOAuthMetadata {
        let server = try MCPOAuthSecurity.publicHTTPS(serverURL)
        var origin = URLComponents(url: server, resolvingAgainstBaseURL: false)!
        origin.path = ""; origin.query = nil
        let root = origin.url!.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var resourceMetadata: [String: Any]?
        let paths = Array(NSOrderedSet(array: ["/.well-known/oauth-protected-resource" + server.path, "/.well-known/oauth-protected-resource"])) as! [String]
        for path in paths {
            let reply = try await send(request(root + path))
            if reply.status == 200 { resourceMetadata = try json(reply); break }
            guard [404, 405, 401].contains(reply.status) else { throw MCPAuthorizationError.providerRejected(reply.status) }
        }
        if resourceMetadata == nil {
            let reply = try await send(request(serverURL))
            if let header = reply.authenticate,
               let range = header.range(of: #"resource_metadata="[^"\r\n]+""#, options: .regularExpression) {
                let value = String(header[range]).dropFirst("resource_metadata=\"".count).dropLast()
                let metadataReply = try await send(request(String(value)))
                if metadataReply.status == 200 { resourceMetadata = try json(metadataReply) }
            }
        }
        // MCP's older authorization revision used the server origin as its issuer.
        // Atlassian and Intercom still publish this format. Only same-origin well-known
        // metadata is tried; authorization/token URLs are never guessed.
        if resourceMetadata == nil {
            resourceMetadata = ["resource": serverURL, "authorization_servers": [root]]
        }
        guard let resourceMetadata, let resource = resourceMetadata["resource"] as? String,
              let resourceURL = try? MCPOAuthSecurity.publicHTTPS(resource),
              MCPOAuthSecurity.resourceMatches(resourceURL, server: server),
              let issuers = resourceMetadata["authorization_servers"] as? [String], let issuer = issuers.first else { throw MCPAuthorizationError.unsupportedSignIn }
        let issuerURL = try MCPOAuthSecurity.publicHTTPS(issuer)
        guard issuerURL.query == nil else { throw MCPAuthorizationError.invalidMetadata }
        var issuerOrigin = URLComponents(url: issuerURL, resolvingAgainstBaseURL: false)!
        issuerOrigin.path = ""
        let issuerRoot = issuerOrigin.url!.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let issuerPath = issuerURL.path == "/" ? "" : issuerURL.path
        let candidates = [issuerRoot + "/.well-known/oauth-authorization-server" + issuerPath,
                          issuerRoot + "/.well-known/openid-configuration" + issuerPath,
                          issuer.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/.well-known/openid-configuration"]
        for candidate in Array(NSOrderedSet(array: candidates)) as! [String] {
            let reply = try await send(request(candidate))
            if [404, 405].contains(reply.status) { continue }
            guard reply.status == 200 else { throw MCPAuthorizationError.providerRejected(reply.status) }
            let metadata = try json(reply)
            guard metadata["issuer"] as? String == issuer,
                  (metadata["code_challenge_methods_supported"] as? [String])?.contains("S256") == true,
                  let authorization = metadata["authorization_endpoint"] as? String,
                  let token = metadata["token_endpoint"] as? String else { throw MCPAuthorizationError.invalidMetadata }
            _ = try MCPOAuthSecurity.publicHTTPS(authorization); _ = try MCPOAuthSecurity.publicHTTPS(token)
            let registration = metadata["registration_endpoint"] as? String
            let revocation = metadata["revocation_endpoint"] as? String
            if let registration { _ = try MCPOAuthSecurity.publicHTTPS(registration) }
            if let revocation { _ = try MCPOAuthSecurity.publicHTTPS(revocation) }
            let methods = metadata["token_endpoint_auth_methods_supported"] as? [String] ?? ["client_secret_basic"]
            guard let authMethod = ["none", "client_secret_post", "client_secret_basic"].first(where: methods.contains) else { throw MCPAuthorizationError.unsupportedSignIn }
            var scopes = resourceMetadata["scopes_supported"] as? [String] ?? []
            if (metadata["scopes_supported"] as? [String])?.contains("offline_access") == true { scopes.append("offline_access") }
            return MCPOAuthMetadata(issuer: issuer, authorizationEndpoint: authorization, tokenEndpoint: token,
                registrationEndpoint: registration, revocationEndpoint: revocation, resource: resource,
                scopes: Array(Set(scopes)).sorted(), authMethod: authMethod)
        }
        throw MCPAuthorizationError.unsupportedSignIn
    }

    func register(metadata: MCPOAuthMetadata) async throws -> MCPOAuthClient {
        guard let endpoint = metadata.registrationEndpoint else { throw MCPAuthorizationError.providerRegistrationRequired }
        let body: [String: Any] = ["client_name": "OpenResponses", "client_uri": "https://github.com/Gunnarguy/OpenResponses",
            "redirect_uris": [MCPOAuthSecurity.redirectURI], "grant_types": ["authorization_code", "refresh_token"],
            "response_types": ["code"], "token_endpoint_auth_method": metadata.authMethod, "application_type": "native"]
        let reply = try await send(request(endpoint, method: "POST", data: JSONSerialization.data(withJSONObject: body)))
        guard [200, 201].contains(reply.status) else {
            if [400, 401, 403].contains(reply.status) { throw MCPAuthorizationError.providerRegistrationRequired }
            throw MCPAuthorizationError.providerRejected(reply.status)
        }
        let response = try json(reply)
        guard let id = response["client_id"] as? String, !id.isEmpty,
              let redirects = response["redirect_uris"] as? [String], redirects.contains(MCPOAuthSecurity.redirectURI) else { throw MCPAuthorizationError.invalidMetadata }
        let method = response["token_endpoint_auth_method"] as? String ?? metadata.authMethod
        guard method == metadata.authMethod else { throw MCPAuthorizationError.invalidMetadata }
        let secret = response["client_secret"] as? String
        guard method == "none" || secret?.isEmpty == false else { throw MCPAuthorizationError.invalidMetadata }
        return MCPOAuthClient(id: id, secret: secret, authMethod: method)
    }

    func authorizationURL(metadata: MCPOAuthMetadata, client: MCPOAuthClient, state: String, verifier: String) throws -> URL {
        var components = URLComponents(url: try MCPOAuthSecurity.publicHTTPS(metadata.authorizationEndpoint), resolvingAgainstBaseURL: false)!
        let parameters = ["response_type": "code", "client_id": client.id, "redirect_uri": MCPOAuthSecurity.redirectURI,
            "state": state, "code_challenge": MCPOAuthSecurity.challenge(verifier), "code_challenge_method": "S256",
            "resource": metadata.resource, "scope": metadata.scopes.joined(separator: " ")]
        components.queryItems = (components.queryItems ?? []).filter { parameters[$0.name] == nil } + parameters.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw MCPAuthorizationError.invalidMetadata }
        return url
    }

    func exchange(code: String, verifier: String, metadata: MCPOAuthMetadata, client: MCPOAuthClient) async throws -> MCPOAuthCredential {
        try await tokens(["grant_type": "authorization_code", "code": code, "code_verifier": verifier, "redirect_uri": MCPOAuthSecurity.redirectURI], metadata: metadata, client: client, oldRefresh: nil)
    }

    func refresh(_ credential: MCPOAuthCredential) async throws -> MCPOAuthCredential {
        guard let refresh = credential.refreshToken, !refresh.isEmpty else { throw MCPAuthorizationError.expired }
        return try await tokens(["grant_type": "refresh_token", "refresh_token": refresh], metadata: credential.metadata, client: credential.client, oldRefresh: refresh)
    }

    private func tokens(_ grant: [String: String], metadata: MCPOAuthMetadata, client: MCPOAuthClient, oldRefresh: String?) async throws -> MCPOAuthCredential {
        var form = grant
        form["client_id"] = client.id
        form["resource"] = metadata.resource
        if client.authMethod == "client_secret_post" { form["client_secret"] = client.secret }
        var request = try request(metadata.tokenEndpoint, method: "POST", data: MCPOAuthSecurity.form(form), contentType: "application/x-www-form-urlencoded")
        if client.authMethod == "client_secret_basic", let secret = client.secret {
            let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
            let credentials = client.id.addingPercentEncoding(withAllowedCharacters: allowed)! + ":" + secret.addingPercentEncoding(withAllowedCharacters: allowed)!
            request.setValue("Basic " + Data(credentials.utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        }
        let reply = try await send(request)
        guard reply.status == 200 else {
            if let object = try? json(reply), ["invalid_grant", "invalid_token"].contains(object["error"] as? String ?? "") { throw MCPAuthorizationError.expired }
            throw MCPAuthorizationError.providerRejected(reply.status)
        }
        let response = try json(reply)
        guard let token = response["access_token"] as? String, !token.isEmpty,
              (response["token_type"] as? String)?.lowercased() == "bearer",
              !token.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else { throw MCPAuthorizationError.invalidMetadata }
        let seconds = (response["expires_in"] as? NSNumber)?.doubleValue ?? Double(response["expires_in"] as? String ?? "")
        if let seconds, !seconds.isFinite || seconds <= 0 { throw MCPAuthorizationError.expired }
        return MCPOAuthCredential(metadata: metadata, client: client, accessToken: token,
            refreshToken: response["refresh_token"] as? String ?? oldRefresh,
            expiresAt: seconds.map { Date().addingTimeInterval($0) }, scope: response["scope"] as? String)
    }
}
