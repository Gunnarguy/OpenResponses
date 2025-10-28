# Notion MCP Quick Start Guide

## 🎯 What You're Building

After setup, you'll be able to say things like:
- "List my Notion databases"
- "Create a new page in my Projects database"
- "Search my Notion workspace for meeting notes"
- "Show me the content of page X"

The AI will naturally understand and execute these using the Notion MCP server!

## 📋 Prerequisites

1. A Notion account with workspace access
2. A Notion integration token (we'll get this below)
3. *(Optional, self-hosting only)* A way to host the Notion MCP server publicly (Railway recommended - free tier works!)

## ✅ Recommended: Use the Official Notion Connector (No Server Hosting)

1. **Create a Notion integration token** (follow Part 1 below).
2. **Share** any pages or databases with that integration so it can access your workspace content.
3. **Open OpenResponses** → `Settings` → `Tools` → tap **Connect Apps** and choose **Notion**.
4. **Paste your integration token** into the OAuth field and decide whether you want the assistant to request approval before each action.
5. *(Optional)* Tap **Choose Notion tools** to open the in-app selector. You can enable everything for full create/search/update/delete support, or pick a subset to reduce context usage.
6. Start a chat and ask the assistant to search, create, update, or delete Notion content—no MCP server deployment required.

> Prefer running your own MCP server? Continue with Part 2 for self-hosted options.

## 🚀 Step-by-Step Setup

### Part 1: Get Your Notion Integration Token

1. **Go to Notion Integrations**
   - Visit: https://www.notion.so/my-integrations
   - Click "New integration"

2. **Create Integration**
   - Name it something like "OpenResponses MCP"
   - Select your workspace
   - Keep default capabilities (Read, Update, Insert)
   - Click "Submit"

3. **Copy Your Token**
   - You'll see an "Internal Integration Token"
   - It starts with `secret_` 
   - **Copy this token** - you'll need it twice (once for deployment, once for the app)

4. **Share Pages with Integration**
   - In Notion, open each database/page you want the AI to access
   - Click the "..." menu → "Add connections"
   - Select your integration
   - Repeat for all pages/databases you want to use

### Part 2: Deploy the Notion MCP Server (Optional)

#### Option A: Railway (Recommended - Easiest)

1. **Fork the Repository**
   - Go to: https://github.com/modelcontextprotocol/servers
   - Click "Fork" to create your own copy

2. **Deploy to Railway**
   - Visit: https://railway.app
   - Sign up/login (free tier is fine)
   - Click "New Project" → "Deploy from GitHub repo"
   - Select your forked `servers` repository
   - In the deployment settings:
     - **Root Directory**: `src/notion`
     - **Environment Variables**: 
       - `NOTION_API_KEY` = your token from Part 1 (starts with `secret_`)
       - `PORT` = `8080`
   - Click "Deploy"

3. **Get Your Server URL**
   - Once deployed, Railway will give you a public URL
   - It looks like: `https://your-app.up.railway.app`
   - The full endpoint will be: `https://your-app.up.railway.app/sse`
   - **Copy this full URL** - you'll need it for the app

#### Option B: Fly.io

```bash
# Clone the repository
git clone https://github.com/modelcontextprotocol/servers.git
cd servers/src/notion

# Create fly.toml
cat > fly.toml << EOF
app = "my-notion-mcp"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
EOF

# Deploy
flyctl launch
flyctl secrets set NOTION_API_KEY=your_secret_token_here
flyctl deploy

# Get your URL
flyctl info
# Your endpoint: https://my-notion-mcp.fly.dev/sse
```

#### Option C: Docker (Self-Hosted)

```bash
# Clone and build
git clone https://github.com/modelcontextprotocol/servers.git
cd servers/src/notion

docker build -t notion-mcp .
docker run -d -p 8080:8080 \
  -e NOTION_API_KEY=your_secret_token_here \
  notion-mcp

# If you need HTTPS, put it behind nginx or use a tunnel service
```

### Part 3: Configure OpenResponses App

1. **Open Settings in OpenResponses**
   - Tap the Settings icon in the app
   - Scroll to "MCP Connectors"
   - Tap "Connect Your Apps"

2. **Find Notion**
   - You'll see Notion with an orange **🖥️ server badge**
   - This indicates it requires a remote server
   - Tap the Notion card

3. **Enter Server Configuration**
   - **Server Label**: Any friendly name (e.g., "My Notion Server")
   - **Server URL**: Your deployment URL + `/sse`
     - Railway: `https://your-app.up.railway.app/sse`
     - Fly.io: `https://my-notion-mcp.fly.dev/sse`
   - **Authorization Token**: Your Notion integration token (starts with `secret_`)
   - **Allowed Tools** (optional): Leave blank to allow all tools
   - **Require Approval**: Choose "always", "prompt", or "never"

4. **Save Configuration**
   - Tap "Save"
   - The configuration is stored securely in your device's Keychain

## 🧪 Testing Your Setup

1. **Start a New Conversation**
   - Go back to the chat view
   - Make sure your active prompt shows the "notion-mcp-official" remote server with the URL `https://mcp.notion.com/mcp`

2. **Test with Simple Commands**
   ```
   List my Notion databases
   ```
   
   The AI should:
   - List the available MCP tools from your server
   - Call `notion_search` or `notion_list_databases`
   - Show you your Notion databases

3. **Try More Advanced Tasks**
   ```
   Create a new page called "Test Page" in my Projects database
   ```
   
   ```
   Search my workspace for pages about "meetings"
   ```

## 🔍 Troubleshooting

### "Connector with ID 'connector_notion' not found"
- This means the request tried to use the hosted-connector path (which is not yet available for Notion)
- Solution: Delete the Notion configuration and re-add it using the remote server setup. The gallery auto-fills the official endpoint described at <https://modelcontextprotocol.io/docs/getting-started/intro>.

### "Connection failed" or timeout errors
- Check that your server is running: Visit your server URL in a browser
- Verify the URL ends with `/sse`
- Check your server logs for errors

### "No tools listed" or "No databases found"
- Verify your Notion integration token is correct
- Make sure you've shared pages/databases with your integration in Notion
- Check the server logs for authentication errors

### Server logs (Railway)
- Go to your Railway project
- Click on the deployment
- View the logs to see what's happening

### Server logs (Fly.io)
```bash
flyctl logs
```

## 🔐 Security Notes

- **Token Storage**: Your Notion token is stored securely in the iOS Keychain, never in plain text
- **Server Access**: Your MCP server should only be accessible via HTTPS
- **Approval Mode**: Set to "always" for maximum control over what the AI can do
- **Shared Pages Only**: The integration can only access pages/databases you explicitly share with it

## 📚 Available Notion Tools

Once configured, the AI has access to these tools:

- `notion_search` - Search across your workspace
- `notion_get_page` - Get a specific page's content
- `notion_get_database` - Get database structure
- `notion_query_database` - Query database entries
- `notion_get_block_children` - Get block content
- `notion_append_block_children` - Add content to pages
- `notion_create_page` - Create new pages
- `notion_update_page` - Modify existing pages

## 🎉 What You Can Do Now

With Notion MCP configured, you can:

1. **Natural Language Database Queries**
   - "Show me all tasks due this week"
   - "Find project pages with status 'In Progress'"

2. **Content Creation**
   - "Create a meeting notes page with today's agenda"
   - "Add a new task to my TODO database"

3. **Information Retrieval**
   - "Summarize the content of my planning doc"
   - "What are my upcoming deadlines?"

4. **Workspace Management**
   - "List all my databases and their structures"
   - "Show me recently edited pages"

The AI will understand these natural language requests and use the appropriate Notion API calls via the MCP server!

## 🔄 Updating Your Configuration

To change your server URL or token:
1. Go to Settings → MCP Connectors
2. Tap Notion again
3. Update the fields
4. Tap Save

The new configuration takes effect immediately.

## 💡 Pro Tips

1. **Use Descriptive Database Names**: The AI uses database names to understand your intent
2. **Structure Your Databases**: Well-structured databases with clear properties work best
3. **Test Incrementally**: Start with simple queries before complex operations
4. **Monitor Approvals**: If using "prompt" mode, you'll see what the AI wants to do before it does it
5. **Check Logs**: Your server logs show all API calls for debugging

---

**Need Help?** Check the full MCP documentation at https://modelcontextprotocol.io or the Notion MCP server GitHub repo.
