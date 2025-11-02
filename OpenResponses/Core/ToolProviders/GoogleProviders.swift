import Foundation
import AuthenticationServices
import CommonCrypto

// MARK: - Public Models

public struct GmailThreadSummary: Codable, Hashable, Identifiable {
    public var id: String { gmailId }
    let gmailId: String
    public let snippet: String
}

public struct GCalEventSummary: Codable, Hashable, Identifiable {
    public var id: String { eventId }
    let eventId: String
    public let summary: String
    public let start: String
    public let end: String
}

public struct GContactSummary: Codable, Hashable {
    public let name: String
    public let email: String?
}

// MARK: - OAuth 2.0 PKCE Core (Shared)

struct OAuthConfig {
    let clientId: String
    let authURL: URL
    let tokenURL: URL
    let redirectScheme: String // e.g., com.yourapp.oauth:/oauth2redirect
    let scopes: [String]
}

struct OAuthTokens: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String?
    let token_type: String
    var created_at: Date = .init()
}

final class OAuthPKCE: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var presentationAnchor: ASPresentationAnchor?

    init(anchor: ASPresentationAnchor?) {
        self.presentationAnchor = anchor
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentationAnchor ?? ASPresentationAnchor()
    }

    static func random(length: Int = 32) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    static func codeChallenge(from verifier: String) -> String {
        func sha256(_ s: String) -> Data {
            var context = CC_SHA256_CTX()
            CC_SHA256_Init(&context)
            let data = s.data(using: .utf8)!
            data.withUnsafeBytes {
                _ = CC_SHA256_Update(&context, $0.baseAddress, CC_LONG(data.count))
            }
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256_Final(&hash, &context)
            return Data(hash)
        }
        func base64url(_ data: Data) -> String {
            data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        return base64url(sha256(verifier))
    }

    func beginAuth(config: OAuthConfig) async throws -> (tokens: OAuthTokens, raw: Data) {
        let verifier = OAuthPKCE.random()
        let challenge = OAuthPKCE.codeChallenge(from: verifier)
        let state = OAuthPKCE.random()
        let scope = config.scopes.joined(separator: " ")
        
        var comps = URLComponents(url: config.authURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "client_id", value: config.clientId),
            .init(name: "redirect_uri", value: config.redirectScheme),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: scope),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "state", value: state),
            .init(name: "access_type", value: "offline"),
            .init(name: "prompt", value: "consent")
        ]
        let authURL = comps.url!

        let code: String = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: config.redirectScheme.components(separatedBy: ":").first) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url = url,
                      let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let code = comps.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: code)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            session.start()
        }

        var req = URLRequest(url: config.tokenURL)
        req.httpMethod = "POST"
        var body = URLComponents()
        body.queryItems = [
            .init(name: "code", value: code),
            .init(name: "client_id", value: config.clientId),
            .init(name: "grant_type", value: "authorization_code"),
            .init(name: "redirect_uri", value: config.redirectScheme),
            .init(name: "code_verifier", value: verifier)
        ]
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = body.query?.data(using: .utf8)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }
        let tokens = try JSONDecoder().decode(OAuthTokens.self, from: data)
        return (tokens, data)
    }
}

// MARK: - Gmail Provider

public final class GmailProvider: ToolProvider, GmailReadable {
    public let kind: ToolKind = .gmail
    public let capabilities: ProviderCapability = [.listEmails]
    private let tokenKey = "oauth.gmail.tokens"
    private let http = HttpClient()
    private let cfg = OAuthConfig(
        clientId: GoogleConfig.clientID,
        authURL: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
        tokenURL: URL(string: "https://oauth2.googleapis.com/token")!,
        redirectScheme: GoogleConfig.redirectScheme,
        scopes: ["https://www.googleapis.com/auth/gmail.readonly"]
    )

    public init() {}

    public func connect(presentingAnchor: ASPresentationAnchor?) async throws {
        if TokenStore.read(account: tokenKey) == nil {
            let pkce = OAuthPKCE(anchor: presentingAnchor)
            let (_, raw) = try await pkce.beginAuth(config: cfg)
            _ = TokenStore.save(raw, account: tokenKey)
        }
    }

    public func listRecentThreads(max: Int = 10) async throws -> [GmailThreadSummary] {
        guard let raw = TokenStore.read(account: tokenKey),
              let tokens = try? JSONDecoder().decode(OAuthTokens.self, from: raw) else {
            throw URLError(.userAuthenticationRequired)
        }
        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/threads?maxResults=\(max)")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(tokens.access_token)", forHTTPHeaderField: "Authorization")
        let (data, _, _) = try await http.send(req)
        struct ListResp: Codable { struct Thread: Codable { let id: String; let snippet: String? }; let threads: [Thread]? }
        let parsed = try JSONDecoder().decode(ListResp.self, from: data)
        return (parsed.threads ?? []).map { .init(gmailId: $0.id, snippet: $0.snippet ?? "") }
    }
}

// MARK: - Google Calendar Provider

public final class GCalProvider: ToolProvider, CalendarReadable {
    public let kind: ToolKind = .gcal
    public let capabilities: ProviderCapability = [.listEvents]
    private let tokenKey = "oauth.gcal.tokens"
    private let http = HttpClient()
    private let cfg = OAuthConfig(
        clientId: GoogleConfig.clientID,
        authURL: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
        tokenURL: URL(string: "https://oauth2.googleapis.com/token")!,
        redirectScheme: GoogleConfig.redirectScheme,
        scopes: ["https://www.googleapis.com/auth/calendar.readonly"]
    )

    public init() {}

    public func connect(presentingAnchor: ASPresentationAnchor?) async throws {
        if TokenStore.read(account: tokenKey) == nil {
            let pkce = OAuthPKCE(anchor: presentingAnchor)
            let (_, raw) = try await pkce.beginAuth(config: cfg)
            _ = TokenStore.save(raw, account: tokenKey)
        }
    }

    public func listEvents(startISO8601: String, endISO8601: String, max: Int = 50) async throws -> [GCalEventSummary] {
        guard let raw = TokenStore.read(account: tokenKey),
              let tokens = try? JSONDecoder().decode(OAuthTokens.self, from: raw) else {
            throw URLError(.userAuthenticationRequired)
        }
        var comps = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        comps.queryItems = [
            .init(name: "timeMin", value: startISO8601),
            .init(name: "timeMax", value: endISO8601),
            .init(name: "singleEvents", value: "true"),
            .init(name: "maxResults", value: "\(max)")
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(tokens.access_token)", forHTTPHeaderField: "Authorization")
        let (data, _, _) = try await http.send(req)
        struct Resp: Codable { struct E: Codable { let id: String; let summary: String?; let start: T; let end: T; struct T: Codable { let dateTime: String?; let date: String? } }; let items: [E]? }
        let parsed = try JSONDecoder().decode(Resp.self, from: data)
        return (parsed.items ?? []).map { e in
            .init(eventId: e.id, summary: e.summary ?? "(no title)",
                  start: e.start.dateTime ?? e.start.date ?? "",
                  end: e.end.dateTime ?? e.end.date ?? "")
        }
    }
}

// MARK: - Google Contacts Provider

public final class GContactsProvider: ToolProvider, ContactsReadable {
    public let kind: ToolKind = .gcontacts
    public let capabilities: ProviderCapability = [.listContacts]
    private let tokenKey = "oauth.gcontacts.tokens"
    private let http = HttpClient()
    private let cfg = OAuthConfig(
        clientId: GoogleConfig.clientID,
        authURL: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
        tokenURL: URL(string: "https://oauth2.googleapis.com/token")!,
        redirectScheme: GoogleConfig.redirectScheme,
        scopes: ["https://www.googleapis.com/auth/contacts.readonly"]
    )

    public init() {}

    public func connect(presentingAnchor: ASPresentationAnchor?) async throws {
        if TokenStore.read(account: tokenKey) == nil {
            let pkce = OAuthPKCE(anchor: presentingAnchor)
            let (_, raw) = try await pkce.beginAuth(config: cfg)
            _ = TokenStore.save(raw, account: tokenKey)
        }
    }

    public func searchContacts(query: String, max: Int = 25) async throws -> [GContactSummary] {
        guard let raw = TokenStore.read(account: tokenKey),
              let tokens = try? JSONDecoder().decode(OAuthTokens.self, from: raw) else {
            throw URLError(.userAuthenticationRequired)
        }
        var comps = URLComponents(string: "https://people.googleapis.com/v1/people:searchContacts")!
        comps.queryItems = [
            .init(name: "query", value: query),
            .init(name: "readMask", value: "names,emailAddresses"),
            .init(name: "pageSize", value: "\(max)")
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(tokens.access_token)", forHTTPHeaderField: "Authorization")
        let (data, _, _) = try await http.send(req)
        struct Resp: Codable { struct P: Codable { let names: [N]?; let emailAddresses: [E]?; struct N: Codable { let displayName: String? }; struct E: Codable { let value: String? } }; let results: [R]?; struct R: Codable { let person: P? } }
        let parsed = try JSONDecoder().decode(Resp.self, from: data)
        return (parsed.results ?? []).compactMap { r in
            let name = r.person?.names?.first?.displayName ?? "(unknown)"
            let email = r.person?.emailAddresses?.first?.value
            return .init(name: name, email: email)
        }
    }
}
