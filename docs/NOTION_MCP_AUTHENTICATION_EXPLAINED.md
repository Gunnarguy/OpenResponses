# Notion MCP Authentication Methods Explained

This document clarifies the different authentication approaches for Notion MCP integration.

---

## 🔐 Authentication Overview

Notion MCP supports **two deployment models**, each with different authentication requirements:

### 1. **Official Notion-Hosted MCP** (`https://mcp.notion.com/mcp`)
- **Hosted by:** Notion
- **Transport:** Streamable HTTP
- **Authentication:** OAuth (preferred) OR Manual Integration Token

### 2. **Self-Hosted MCP** (Docker container)
- **Hosted by:** You (Docker on your infrastructure)
- **Transport:** HTTP with custom endpoint
- **Authentication:** Two-tier system (Notion token + Bearer token)

---

## Method 1: Official Hosted MCP

### Authentication Flow

**For AI tools with native Notion OAuth support** (e.g., Claude Desktop, ChatGPT with MCP):
1. Tool initiates OAuth flow
2. User logs into Notion
3. User grants permissions
4. Tool receives OAuth token automatically
5. ✅ **No manual token management needed**

**For AI tools without OAuth support** (e.g., OpenResponses manual connection):
1. User creates Notion Integration at https://www.notion.so/profile/integrations
2. User copies Integration Token (starts with `secret_` or `ntn_`)
3. User pastes token into app's Authorization field
4. User must manually share pages/databases with the integration
5. ✅ **Manual token entry required**

### Important Notes

- **Token Type:** Notion Integration Token (OAuth or Internal Integration)
- **Format:** `secret_xxxxx` or `ntn_xxxxx`
- **Where to get it:** https://www.notion.so/profile/integrations
- **Permissions:** Must explicitly share pages/databases with your integration
- **URL:** `https://mcp.notion.com/mcp`

### OpenResponses Configuration

```
Server Label: notion-mcp-official
Server URL: https://mcp.notion.com/mcp
Authorization: <Your Notion Integration Token>
Require Approval: never (for testing) or always (for production)
```

---

## Method 2: Self-Hosted MCP (Docker)

### Two-Tier Authentication

This method requires **two different tokens**:

#### Token 1: Notion API Token
- **Purpose:** Container authenticates to Notion's API
- **Location:** Docker environment variable `NOTION_TOKEN`
- **Format:** `ntn_xxxxx` (OAuth) or `secret_xxxxx` (Internal Integration)
- **Get it from:** https://www.notion.so/profile/integrations
- **Used by:** The MCP server container to access your Notion workspace

#### Token 2: Bearer Token
- **Purpose:** OpenAI/Your app authenticates to YOUR MCP server
- **Location:** App's Authorization field
- **Format:** Long alphanumeric string (e.g., `35b17eb13a7613a5...`)
- **Get it from:** Docker container logs (`docker logs <container>`)
- **Used by:** OpenAI's API to securely connect to your MCP server
- **Important:** Regenerates on every container restart

### Why Two Tokens?

```
┌─────────────┐                  ┌──────────────┐                  ┌────────────┐
│ OpenResponses│  Bearer Token    │ Docker MCP   │  Notion Token    │   Notion   │
│     App     │ ──────────────>  │   Server     │ ──────────────>  │    API     │
└─────────────┘                  └──────────────┘                  └────────────┘
                Authorization        Environment                     Integration
                 (Your Server)         Variable                        Token
```

### OpenResponses Configuration

```
Server Label: notion-mcp-custom
Server URL: https://your-ngrok-url.ngrok-free.app/mcp
Authorization: <Bearer token from Docker logs>
Require Approval: never
```

### Getting the Bearer Token

```bash
# Start container
docker run -d \
  --name notion-mcp \
  -p 8080:3000 \
  -e NOTION_TOKEN=<YOUR_NOTION_TOKEN> \
  mcp/notion \
  notion-mcp-server --transport http --port 3000

# Get the Bearer token from logs
docker logs notion-mcp | grep "Generated auth token"
```

Output will show:
```
Generated auth token: 35b17eb13a7613a5e6e61dcdf6e1c116f1f36a8b3c5e630b813f53222a39225b
```

---

## 🔄 Switching Between Methods in OpenResponses

### Template System (Fixed in Latest Version)

When you select a template in the app:
1. **Server Label changes** → Determines keychain storage key
2. **Server URL changes** → Points to correct endpoint
3. **Authorization field updates automatically:**
   - Loads saved token for selected server label (if exists)
   - Clears field if no saved token
4. **Token auto-saves to keychain** when you type/paste

### Example: Switching Flow

**Step 1: Configure Official**
```
Select: "Notion MCP (Official)"
URL auto-fills: https://mcp.notion.com/mcp
Authorization: Paste your Notion token (ntn_xxx)
→ Saves to keychain under key "notion-mcp-official"
```

**Step 2: Switch to Self-Hosted**
```
Select: "Notion MCP (Self-Hosted)"
URL auto-fills: https://your-ngrok-url.ngrok-free.app/mcp
Authorization: Auto-loads saved token (if exists) OR clears field
→ Paste Bearer token from Docker logs
→ Saves to keychain under key "notion-mcp-custom"
```

**Step 3: Switch Back to Official**
```
Select: "Notion MCP (Official)"
URL auto-fills: https://mcp.notion.com/mcp
Authorization: Auto-loads your Notion token (ntn_xxx)
→ No need to re-enter! Already saved.
```

✅ **Each server maintains its own token independently**

---

## 🔑 Token Storage Security

### Keychain Storage Keys

- Official: `"mcp_manual_notion-mcp-official"`
- Self-Hosted: `"mcp_manual_notion-mcp-custom"`

### How It Works

1. **User enters token** → Stored in iOS Keychain (encrypted)
2. **User switches templates** → Loads correct token from keychain
3. **Token changes** → Auto-saves to keychain immediately
4. **Field cleared** → Token deleted from keychain

### Security Benefits

✅ Tokens never stored in UserDefaults (insecure)
✅ Each server has isolated token storage
✅ Automatic encryption via iOS Keychain
✅ No cross-contamination when switching servers

---

## ⚠️ Common Issues

### "401 Unauthorized" with Official MCP
**Cause:** Invalid or expired Notion token
**Fix:** 
1. Go to https://www.notion.so/profile/integrations
2. Regenerate your integration token
3. Update token in app

### "401 Unauthorized" with Self-Hosted
**Cause:** Bearer token out of sync
**Fix:**
1. Check container is running: `docker ps`
2. Get fresh Bearer token: `docker logs notion-mcp | grep "Generated"`
3. Update token in app

### Self-Hosted Container Keeps Restarting
**Cause:** Invalid Notion token in `NOTION_TOKEN` env var
**Fix:**
1. Stop container: `docker stop notion-mcp`
2. Delete container: `docker rm notion-mcp`
3. Run with correct token

### Pages Not Accessible
**Cause:** Pages not shared with integration
**Fix:**
1. Open page in Notion
2. Click "..." → "Add connections"
3. Select your integration
4. Confirm

---

## 📚 References

- **Official Notion MCP Docs:** https://developers.notion.com/docs/get-started-with-mcp
- **Notion MCP Tools:** https://developers.notion.com/docs/mcp-supported-tools
- **GitHub Repository:** https://github.com/makenotion/notion-mcp-server
- **Create Integration:** https://www.notion.so/profile/integrations
- **MCP Specification:** https://spec.modelcontextprotocol.io

---

**Last Updated:** October 13, 2025
