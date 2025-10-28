import Foundation

/// Bootstraps a ubiquitous MCP configuration at app startup.
/// - Reads existing Prompt + Keychain and ensures MCP is enabled everywhere with safe defaults.
/// - Prefers remote server (manual) config; leaves connector config untouched if already selected.
final class MCPConfigurationService {
    static let shared = MCPConfigurationService()
    private init() {}

    /// Applies global MCP defaults to the active prompt.
    /// - Ensures:
    ///   - enableMCPTool = true
    ///   - if remote server URL/label present, mcpIsConnector = false
    ///   - mcpAllowedTools = "" (allow all tools = ubiquitous)
    ///   - mcpRequireApproval normalized to "never" when empty/"auto"/"allow"
    /// - Does not override an explicitly configured connector flow.
    func bootstrap(chatViewModel: ChatViewModel) {
        var prompt = chatViewModel.activePrompt

        // If the user explicitly chose a connector, keep it, just ensure MCP is enabled and defaults are safe.
        if prompt.mcpIsConnector, let connectorId = prompt.mcpConnectorId, !connectorId.isEmpty {
            prompt.enableMCPTool = true
            // Allow all tools by default (ubiquitous); user can whitelist later
            if prompt.mcpAllowedTools.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                // Respect an existing whitelist if user already set it
            } else {
                prompt.mcpAllowedTools = ""
            }
            // Normalize approval to never unless the user explicitly set always
            prompt.mcpRequireApproval = normalizeApproval(prompt.mcpRequireApproval)
            chatViewModel.activePrompt = prompt
            chatViewModel.saveActivePrompt()
            return
        }

        // Prefer remote server if a URL is present or we have Keychain headers for a label.
        let hasManualLabel = !prompt.mcpServerLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasManualURL = !prompt.mcpServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let manualKey = hasManualLabel ? "mcp_manual_\(prompt.mcpServerLabel)" : nil
        let hasKeychainHeaders = manualKey.flatMap { KeychainService.shared.load(forKey: $0) }?.isEmpty == false

        if hasManualURL || hasKeychainHeaders {
            prompt.enableMCPTool = true
            prompt.mcpIsConnector = false
            // Leave existing label/URL as-is, just enforce ubiquitous defaults
            if prompt.mcpAllowedTools.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                // Respect an existing whitelist if user already set it
            } else {
                prompt.mcpAllowedTools = "" // all tools
            }
            prompt.mcpRequireApproval = normalizeApproval(prompt.mcpRequireApproval)
            chatViewModel.activePrompt = prompt
            chatViewModel.saveActivePrompt()
            return
        }

        // If neither connector nor remote server present, do nothing.
        // The user can configure via Settings → MCP Servers.
    }

    /// Standardize approval strings to API-compliant values
    private func normalizeApproval(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
        case "", "auto", "allow": return "never"
        case "prompt", "ask", "review", "confirm": return "always"
        case "always", "never": return trimmed
        case "deny": return "always"
        default: return trimmed
        }
    }
}
