# Notion MCP Integration Guide

## Overview

OpenResponses now supports **two ways** to connect to Notion via MCP:

1. **Official Notion MCP** (Recommended) - `https://mcp.notion.com/mcp`
2. **Custom Self-Hosted** - Your own deployed Notion MCP server

## Quick Start: Official Notion MCP

### Option 1: One-Click Setup (Easiest)

1. Open **Settings** in OpenResponses
2. Scroll to **MCP Servers** section
3. Tap **"Add Notion MCP (Official)"**
4. The app pre-fills:
   - Server URL: `https://mcp.notion.com/mcp`
   - Server Label: `Notion MCP (Official)`
   - All 14 Notion tools enabled
5. Tap **"Authorize with Notion"**
6. Complete OAuth flow in browser
7. Done! ✅

### Option 2: Manual Configuration

If you prefer manual setup:

**Server Details:**
- **URL**: `https://mcp.notion.com/mcp`
- **Label**: `Notion MCP (Official)` (or your choice)
- **Authorization**: OAuth via Notion app or manual token
- **Approval**: `never` (tools are safe by default)

**Available Tools:**
- `notion-search` - Search across workspace and connected tools
- `notion-fetch` - Get page/database content by URL
- `notion-create-pages` - Create new pages
- `notion-update-page` - Update page properties/content
- `notion-move-pages` - Reorganize workspace
- `notion-duplicate-page` - Copy pages/templates
- `notion-create-database` - Create new databases
- `notion-update-database` - Modify database properties
- `notion-create-comment` - Add comments to pages
- `notion-get-comments` - Read page comments
- `notion-get-teams` - List teamspaces
- `notion-get-users` - Get workspace users
- `notion-get-user` - Get user by ID
- `notion-get-self` - Get current bot/user info

### Authorization Options

#### Via Notion App (Recommended)
1. Open Notion desktop/mobile app
2. Go to **Settings** → **Connections** → **Notion MCP**
3. Choose your AI tool (OpenResponses)
4. Complete OAuth flow
5. Copy the authorization token
6. Paste into OpenResponses MCP settings

#### Manual Token
If OAuth isn't available:
1. Visit https://www.notion.so/my-integrations
2. Click **"+ New integration"**
3. Name it (e.g., "OpenResponses")
4. Select your workspace
5. Copy the **Internal Integration Token**
6. In Notion, **share pages/databases** with your integration
7. Paste token into OpenResponses authorization field

## Rate Limits

From [Notion's docs](https://developers.notion.com/reference/rate-limits):

- **General**: 180 requests/minute (3 req/sec average)
- **Search-specific**: 30 requests/minute
- **Rate limit handling**: Automatic retry with exponential backoff

## Differences: Official vs Self-Hosted

| Feature | Official MCP | Self-Hosted |
|---------|-------------|-------------|
| **URL** | `https://mcp.notion.com/mcp` | Your deployment URL |
| **Setup** | One-click OAuth | Deploy + configure |
| **Maintenance** | Notion handles updates | You manage updates |
| **Rate Limits** | Notion's standard limits | Your server's limits |
| **Availability** | 99.9% uptime | Depends on your host |
| **OAuth** | Built-in | Manual config required |
| **Cost** | Free | Hosting costs apply |
| **Best For** | Most users | Enterprise/custom needs |

## Migration: Self-Hosted → Official

If you're currently using a self-hosted Notion MCP:

### Why Migrate?
- ✅ No deployment/maintenance needed
- ✅ Built-in OAuth flow
- ✅ Automatic updates
- ✅ Better reliability
- ✅ Simpler setup

### How to Migrate

1. **Keep current config** (don't delete yet)
2. **Add official Notion MCP**:
   - Use template: `RemoteMCPServer.notionOfficial`
   - Authorize with Notion OAuth
3. **Test the official server**:
   - Send test query: "List my Notion databases"
   - Verify tool calls work
4. **Remove self-hosted config** (once confirmed working)
5. **Optional**: Shut down self-hosted server to save costs

### Switching in Active Prompt

1. Open **Settings** → **Prompts**
2. Select your active prompt
3. Scroll to **MCP Tool** section
4. Change **Server Label** to `Notion MCP (Official)`
5. Save prompt
6. Done!

## Connection Methods

Official Notion MCP supports multiple transport protocols:

### 1. Streamable HTTP (Default)
```swift
// What OpenResponses uses
serverURL: "https://mcp.notion.com/mcp"
```

**Best for**: iOS apps, web clients, most use cases

### 2. SSE (Server-Sent Events)
```swift
// Alternative for streaming-focused apps
serverURL: "https://mcp.notion.com/sse"
```

**Best for**: Apps that prefer SSE over HTTP streaming

### 3. STDIO (Local Only)
```bash
# For desktop/CLI tools only
npx -y mcp-remote https://mcp.notion.com/mcp
```

**Not applicable**: iOS doesn't support STDIO

## Troubleshooting

### "Authorization failed"
1. Verify token is correct (starts with `secret_` for manual, or OAuth token)
2. Check token hasn't expired
3. Try re-authorizing via Notion app

### "Rate limit exceeded"
1. Wait 60 seconds before retrying
2. Reduce parallel tool calls
3. Use caching when possible

### "Page not found"
1. Ensure page is shared with your Notion integration
2. Check page URL is correct
3. Verify integration has access to workspace

### "Tool not found"
1. Confirm server URL is `https://mcp.notion.com/mcp`
2. Check `mcp_list_tools` response in logs
3. Verify no typos in tool names

### Connection Issues
1. **Check internet**: Official MCP requires network access
2. **Verify URL**: Must be HTTPS, not HTTP
3. **Test in browser**: Visit https://mcp.notion.com/mcp (should return 200)
4. **Check logs**: Look for connection errors in console

## Example Prompts

### Search
- "Find all meeting notes from last week"
- "Search for pages mentioning 'Q4 goals'"
- "Look for project specs in my Engineering database"

### Fetch
- "Get the content from https://notion.so/page-url"
- "What's in my product roadmap page?"
- "Read the latest weekly report"

### Create
- "Create a new meeting notes page for today's standup"
- "Make a project kickoff template in my Projects folder"
- "Add a new task to my TODO database with status 'Not Started'"

### Update
- "Change the status of this project to 'Complete'"
- "Update the due date on my task to next Friday"
- "Add a risks section to the project plan"

### Organize
- "Move all Q3 reports to the Archive folder"
- "Reorganize my workspace by priority"
- "Duplicate my meeting template for next week"

## Code Structure

### MCPConnector.swift
```swift
struct RemoteMCPServer {
    // Official template for one-click setup
    static let notionOfficial = RemoteMCPServer(
        label: "Notion MCP (Official)",
        serverURL: "https://mcp.notion.com/mcp",
        requireApproval: .never,
        allowedTools: [/* all 14 tools */]
    )
    
    // Pre-configured templates
    static let templates: [RemoteMCPServer] = [
        .notionOfficial,
        // Custom server template...
    ]
}
```

### SettingsView.swift
```swift
// Quick-add button for official Notion MCP
Button("Add Notion MCP (Official)") {
    let notion = RemoteMCPServer.notionOfficial
    activePrompt.mcpServerLabel = notion.label
    activePrompt.mcpServerURL = notion.serverURL
    activePrompt.enableMCPTool = true
    // Trigger OAuth flow...
}
```

## API Reference

Full Notion MCP documentation:
- **Setup Guide**: https://developers.notion.com/docs/connections-guide  
- **Supported Tools**: https://developers.notion.com/reference/supported-tools
- **Rate Limits**: https://developers.notion.com/reference/rate-limits
- **GitHub**: https://github.com/makenotion/notion-mcp

## Advanced: Custom Tools Filter

You can restrict which Notion tools are available:

```swift
var allowedTools: [String]? = [
    "notion-search",   // Only allow search
    "notion-fetch"     // and fetch
]
```

**Use cases**:
- Limit to read-only operations
- Prevent accidental modifications
- Comply with workspace policies
- Reduce API surface for security

## Support

### Official Notion MCP
- **Docs**: https://developers.notion.com/
- **Issues**: https://github.com/makenotion/notion-mcp/issues
- **Community**: Notion Developers Slack

### OpenResponses Integration
- **GitHub**: https://github.com/Gunnarguy/OpenResponses
- **Issues**: File under "MCP Integration" label
- **Docs**: `/docs/GITHUB_MCP_GUIDE.md`

---

## Summary

✅ **Official Notion MCP** is now the recommended way to connect Notion
✅ **Pre-configured template** makes setup one-click
✅ **14 Notion tools** available out of the box  
✅ **Built-in OAuth** flow via Notion app
✅ **Self-hosted option** still available for advanced users

The integration is now **ubiquitous** - whether you use the official server or self-host, the experience is seamless! 🎉
