# Notion MCP Integration Guide

This guide covers **two methods** for integrating Notion with OpenResponses via Model Context Protocol (MCP).

---

## Method 1: Official Notion-Hosted MCP (Easiest)

### Overview
Use Notion's official MCP server hosted at `https://mcp.notion.com/mcp`. This is the simplest method—no Docker, no servers to manage. Notion handles all the infrastructure.

**Important:** The official server uses OAuth authentication. For AI tools that support Notion's OAuth flow (like Claude Desktop), authentication is automatic. For manual connections (like OpenResponses), you'll need to create a Notion integration and use its token.

### Prerequisites
- A Notion account
- A Notion OAuth integration token

### Step 1: Get Your Notion OAuth Token

1. Go to [https://www.notion.so/profile/integrations](https://www.notion.so/profile/integrations)
2. Click **"+ New integration"**
3. Give it a name (e.g., "OpenResponses MCP")
4. Select the workspace you want to connect
5. Set capabilities:
   - ✅ Read content
   - ✅ Update content
   - ✅ Insert content
6. Click **"Submit"**
7. Copy the **Integration Token** (starts with `ntn_` or `secret_`)

### Step 2: Share Pages/Databases with Your Integration

⚠️ **Important:** Your integration can only access pages/databases that are explicitly shared with it.

1. Open a Notion page or database
2. Click **"..."** (three dots) → **"Add connections"**
3. Select your integration (e.g., "OpenResponses MCP")
4. Confirm

Repeat for all pages/databases you want the AI to access.

### Step 3: Configure in OpenResponses App

1. Open **OpenResponses** → **Settings**
2. Scroll to **MCP Configuration**
3. Tap **"Use Template"** → Select **"Notion MCP (Official)"**
4. The app will auto-fill:
   - **Server Label:** `notion-mcp-official`
   - **Server URL:** `https://mcp.notion.com/mcp`
5. In **Authorization**, paste your Notion token
6. Set **Require Approval:** 
   - `never` for trusted use
   - `always` to approve each action
7. Tap **Save**

### Step 4: Test It!

In a chat, try:
```
Search my Notion workspace for pages about "projects"
```

The AI should use the Notion MCP tools to search your workspace.

---

## Method 2: Self-Hosted MCP (Advanced)

### Overview
Run the official `mcp/notion` Docker container on your own infrastructure. This gives you full control and works great for:
- Raspberry Pi home servers
- Docker-based deployments
- Development/testing environments

### Prerequisites
- Docker installed
- (Optional) Ngrok for public access
- A Notion OAuth token (same as Method 1, Steps 1-2 above)

### Step 1: Run the Docker Container

```bash
docker run -d \
  --name notion-mcp \
  --restart unless-stopped \
  -p 8080:3000 \
  -e NOTION_TOKEN=<YOUR_NOTION_TOKEN_HERE> \
  mcp/notion \
  notion-mcp-server --transport http --port 3000
```

**Important:** Replace `<YOUR_NOTION_TOKEN_HERE>` with your actual Notion token.

### Step 2: Get the Bearer Token

The container generates a unique Bearer token on startup. Check the logs:

```bash
docker logs notion-mcp | grep "Bearer token"
```

Copy the Bearer token (long alphanumeric string).

### Step 3: Set Up Public Access (Optional)

If running locally, you can use ngrok to create a public URL:

```bash
ngrok http 8080
```

Copy the HTTPS URL (e.g., `https://abc123.ngrok-free.app`)

**For Raspberry Pi on local network:**
Use your Pi's IP address (e.g., `http://192.168.1.100:8080`)

### Step 4: Configure in OpenResponses App

1. Open **OpenResponses** → **Settings**
2. Scroll to **MCP Configuration**
3. Tap **"Use Template"** → Select **"Notion MCP (Self-Hosted)"**
4. Update the fields:
   - **Server Label:** `notion-mcp-custom` (or any name)
   - **Server URL:** 
     - If using ngrok: `https://your-ngrok-url.ngrok-free.app/mcp`
     - If local network: `http://192.168.1.100:8080/mcp`
   - **Authorization:** Paste the **Bearer token** from Step 2
5. Set **Require Approval:** `never` for testing
6. Tap **Save**

### Step 5: Test It!

Same as Method 1—try searching or creating Notion pages via chat.

---

## Comparison: Official vs. Self-Hosted

| Feature | Official (Method 1) | Self-Hosted (Method 2) |
|---------|-------------------|---------------------|
| **Setup Difficulty** | ⭐ Easy | ⭐⭐⭐ Advanced |
| **Maintenance** | None (Notion manages it) | You manage updates |
| **Reliability** | Notion's uptime | Your infrastructure |
| **Privacy** | Data goes through Notion's servers | Runs on your hardware |
| **Cost** | Free | Free (if self-hosting) |
| **Best For** | Most users | Privacy-conscious users, Pi enthusiasts |

---

## Troubleshooting

### "Authentication failed" or 401 errors

**Official Method:**
- Verify your Notion token is correct
- Ensure pages/databases are shared with your integration

**Self-Hosted Method:**
- Check Bearer token is up-to-date (regenerates on container restart)
- Verify ngrok tunnel is active: `curl -I https://your-ngrok-url.ngrok-free.app/mcp`

### "No tools available"

- Leave **Allowed Tools** empty to enable all tools
- Check **MCP Tool** is enabled in Settings → Tools

### Container won't start

```bash
# Check logs
docker logs notion-mcp

# Common issues:
# 1. Port 8080 already in use → Change to -p 8081:3000
# 2. Invalid Notion token → Double-check the token
```

---

## Available Notion Tools

When connected successfully, the AI can use these tools:

1. **notion_search** - Search workspace for pages/databases
2. **notion_fetch** - Get full content of a page
3. **notion_create_pages** - Create new pages
4. **notion_update_page** - Edit existing pages
5. **notion_move_pages** - Move pages to different parents
6. **notion_duplicate_page** - Duplicate pages
7. **notion_create_database** - Create new databases
8. **notion_update_database** - Modify database properties
9. **notion_create_comment** - Add comments to pages
10. **notion_get_comments** - Retrieve comments
11. **notion_get_teams** - List workspace teams
12. **notion_get_users** - List workspace users
13. **notion_get_user** - Get specific user info
14. **notion_get_self** - Get bot user info

---

## Security Best Practices

1. **Never commit tokens to git** - Use `.gitignore` for config files
2. **Use `require_approval: always`** for production use
3. **Limit integration permissions** in Notion to only what's needed
4. **Rotate tokens periodically** if you suspect compromise
5. **Use HTTPS** (ngrok/official endpoint) - never plain HTTP for remote access

---

## Getting Help

- **Official Notion MCP Docs:** [https://developers.notion.com/docs/mcp](https://developers.notion.com/docs/mcp)
- **MCP Specification:** [https://spec.modelcontextprotocol.io](https://spec.modelcontextprotocol.io)
- **Docker Image:** [https://hub.docker.com/r/mcp/notion](https://hub.docker.com/r/mcp/notion)

---

**Last Updated:** October 13, 2025
