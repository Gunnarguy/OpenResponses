# Notion Integration Guide

**Last Updated:** October 31, 2025

## ✅ Working Path: Direct Notion Integration

The app uses **direct API calls** to Notion's REST API (`api.notion.com`) for reliable access to your workspace.

### How to Connect

1. **Open Settings → MCP Tab**
2. **Click "Direct Notion Integration"** (top button with green "Recommended" badge)
3. **Get your token:**
   - Visit https://www.notion.so/my-integrations
   - Click "+ New integration"
   - Give it a name and select your workspace
   - Copy the "Internal Integration Token" (starts with `secret_` or `ntn_`)
4. **Paste the token** in the app
5. **Click "Connect to Notion"**
6. **Done!** The app will validate your token immediately

### Important: Share Pages with Your Integration

For the integration to access your Notion content:
1. Open the page in Notion web
2. Click "..." → "Add connections"
3. Select your integration
4. Grant access

Without this step, your integration won't see any content.

---

## ❌ Removed: MCP Notion Connector

The MCP-based Notion connector (`connector_notion`) has been **removed** from the app because:

- It required OAuth tokens (not integration tokens)
- The official Notion MCP endpoint (`mcp.notion.com`) didn't work with standard integration tokens
- It added unnecessary complexity

### What Changed

- **Removed:** "Quick Notion HTTP MCP" button from Connector Gallery
- **Removed:** `connector_notion` from MCPConnector library
- **Added:** Direct Notion Integration view (simplified, working path)

---

## Architecture

### Direct Integration (Current)
```
OpenResponses App → api.notion.com/v1/...
```

**Features:**
- Uses `NotionProvider.swift` for direct REST API calls
- Token stored securely in Keychain (`notion.integration`)
- Validates token via `/v1/users/me` endpoint
- No external dependencies or proxies

### MCP Route (Removed)
```
OpenResponses → OpenAI API → mcp.notion.com → Notion
```

**Why it was removed:**
- Required OAuth flow (complex setup)
- Integration tokens didn't work
- Added latency and failure points
- Inconsistent authentication requirements

---

## For Developers

### Using NotionProvider in Code

```swift
// Check if token exists
if let token = TokenStore.readString(account: "notion.integration") {
    // User is connected
}

// Access Notion API
let provider = ToolHub.shared.notion

// List databases under a page
let databases = try await provider.listDatabasesUnderPage(pageId)

// List pages in a database
let pages = try await provider.listPages(inDatabase: databaseId)

// Find specific pages
let results = try await provider.findPages(
    inDatabase: databaseId, 
    titleProperty: "Project Name",
    equals: "OpenResponses"
)
```

### Token Validation

```swift
// Validate token and get bot info
let result = await NotionAuthService.shared.preflight(
    authorizationValue: token
)

if result.ok {
    print("Connected as: \(result.userName ?? "Bot")")
    print("User ID: \(result.userId ?? "-")")
}
```

---

## Troubleshooting

### "401 Unauthorized"
- **Cause:** Invalid or expired token
- **Fix:** Go to notion.so/my-integrations and regenerate your token

### "403 Forbidden"  
- **Cause:** Pages not shared with your integration
- **Fix:** Share the specific pages/databases with your integration in Notion

### "Connection failed"
- **Cause:** Network issue or incorrect token format
- **Fix:** Ensure token starts with `secret_` or `ntn_` and check internet connection

---

## Migration Guide

If you were using the old MCP Notion connector:

1. **Go to Settings → MCP Tab**
2. **Disconnect any existing MCP Notion connections**
3. **Use "Direct Notion Integration"** instead
4. **Paste your same integration token**
5. **Verify it works** using the "Test Connection" button

Your token remains the same - only the connection method changes.

---

## References

- **Notion API Docs:** https://developers.notion.com/reference/intro
- **Create Integration:** https://www.notion.so/my-integrations
- **App Architecture:** See `NotionProvider.swift` and `NotionConnectionView.swift`
