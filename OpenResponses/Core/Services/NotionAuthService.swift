import Foundation
import CryptoKit

/// Centralized Notion auth utilities: token normalization, SHA256 hashing, and /v1/users/me preflight.
final class NotionAuthService {
    static let shared = NotionAuthService()
    private init() {}

    private let notionUsersMeURL = URL(string: "https://api.notion.com/v1/users/me")!
    private let defaultNotionVersion = "2022-06-28"

    // MARK: - Public API

    /// Normalizes an input token/authorization value.
    /// - If input already starts with a known scheme ("Bearer ", "Basic ", "Token "), it is preserved (after cleanup).
    /// - If input contains spaces, it is returned as-is (after cleanup).
    /// - Otherwise, it returns "Bearer <token>".
    func normalizeAuthorizationValue(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        let cleaned = removeInvisibleCharacters(from: trimmed)
        guard !cleaned.isEmpty else { return "" }

        let lower = cleaned.lowercased()
        if lower.hasPrefix("bearer ") || lower.hasPrefix("basic ") || lower.hasPrefix("token ") {
            return cleaned
        }
        if cleaned.contains(" ") {
            return cleaned
        }
        return "Bearer \(cleaned)"
    }

    /// Strips a leading "Bearer " prefix if present and returns the raw token.
    func stripBearer(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        let cleaned = removeInvisibleCharacters(from: trimmed)
        let lower = cleaned.lowercased()
        if lower.hasPrefix("bearer ") {
            return String(cleaned.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
    }

    /// Computes a stable SHA256 hex digest for the provided authorization value (token or "Bearer ..." string).
    /// - The digest is computed over the cleaned raw token (without "Bearer ").
    func tokenHash(fromAuthorizationValue authorizationValue: String) -> String {
        let rawToken = stripBearer(authorizationValue)
        return sha256Hex(rawToken)
    }

    /// Performs a Notion preflight by calling /v1/users/me with the provided authorization value.
    /// - Automatically normalizes the Authorization header and sets Notion-Version (2022-06-28).
    /// - Returns success state, HTTP status, message/body, and parsed user identity if available.
    func preflight(authorizationValue: String, timeout: TimeInterval = 15) async -> (ok: Bool, status: Int, message: String, userId: String?, userName: String?) {
        var req = URLRequest(url: notionUsersMeURL)
        req.httpMethod = "GET"
        req.timeoutInterval = timeout
        req.setValue(normalizeAuthorizationValue(authorizationValue), forHTTPHeaderField: "Authorization")
        req.setValue(defaultNotionVersion, forHTTPHeaderField: "Notion-Version")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            if status == 200 {
                // Attempt to parse minimal identity (id/name) from Notion user object
                let (uid, uname) = parseUserIdentity(from: data)
                return (true, status, "OK", uid, uname)
            } else {
                let body = String(data: data, encoding: .utf8) ?? ""
                return (false, status, body, nil, nil)
            }
        } catch {
            return (false, -1, error.localizedDescription, nil, nil)
        }
    }

    // MARK: - Helpers

    /// Strips control characters and zero-width/invisible Unicode that can accidentally be copied with tokens
    private func removeInvisibleCharacters(from input: String) -> String {
        // Common invisibles: ZERO WIDTH SPACE/NO-JOINER/JOINER, BOM, NBSP
        let forbidden = CharacterSet(charactersIn: "\u{200B}\u{200C}\u{200D}\u{FEFF}\u{00A0}")
        let scalars = input.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0) && !forbidden.contains($0)
        }
        return String(String.UnicodeScalarView(scalars))
    }

    private func sha256Hex(_ text: String) -> String {
        let data = Data(text.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func parseUserIdentity(from data: Data) -> (String?, String?) {
        // Minimal JSON parsing to extract "id" and "name"
        // Notion returns e.g.: { "object":"user","id":"...","name":"...","type":"bot", ... }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let id = json["id"] as? String
            let name = json["name"] as? String
            return (id, name)
        }
        return (nil, nil)
    }
}
