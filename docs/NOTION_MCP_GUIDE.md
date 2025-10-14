# Notion MCP Integration Guide

## Overview

Connect your AI tools to Notion using the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction), an open standard that lets AI assistants interact with your Notion workspace.

## What is Notion MCP?

Notion MCP is Notion's hosted server that gives AI tools secure access to your Notion workspace. It's designed to work seamlessly with popular AI assistants like ChatGPT, Cursor, and Claude.

### Architecture

Notion hosts both the MCP Server and the Public API. Your tools contain MCP clients that connect to the remote MCP server to access Notion's tools.

```
┌─────────────────┐         ┌──────────────────────┐
│   AI Assistant  │         │    Notion Platform   │
│  (MCP Client)   │◄────────┤  MCP Server + API    │
│                 │  HTTPS  │                      │
└─────────────────┘         └──────────────────────┘
```

### Why use Notion MCP?

- **Easy setup** — Connect through simple OAuth, with one-click installation for supported AI tools
- **Full workspace access** — AI tools can read and write to your Notion pages just like you can
- **Optimized for AI** — Built specifically for AI agents with efficient data formatting

## What can you do with Notion MCP?

### Create documentation

Generate PRDs, tech specs, and architecture docs from your research and project data.

### Search and find answers

Let AI search across all your Notion and connected workspace content.

### Manage tasks

Generate code snippets from task descriptions and update project status automatically.

### Build reports

Create release notes, project updates, and performance reports from multiple sources.

### Plan campaigns

Generate comprehensive briefs and track progress across marketing channels.

## Setting up Notion MCP in OpenResponses

### Step 1: Get Notion MCP Server URL

The official Notion MCP server is hosted at:

```
https://api.notion.com/mcp/v1
```

For the latest server URL and configuration, check:

- **Official Documentation**: https://developers.notion.com/docs/mcp
- **GitHub Repository**: https://github.com/makenotion/notion-mcp-server

### Step 2: Create a Notion Integration

1. Go to [Notion Integrations](https://www.notion.so/my-integrations)
2. Click "New integration"
3. Give it a name (e.g., "OpenResponses AI")
4. Select the workspace you want to connect
5. Configure permissions:
   - **Read content** — Required for searching and reading pages
   - **Update content** — Required for creating and editing pages
   - **Insert content** — Required for adding new pages
6. Copy the **Internal Integration Token** (starts with `secret_`)

### Step 3: Share Pages with Integration

Notion integrations don't have access to pages by default. You must explicitly share:

1. Open the Notion page or database you want the AI to access
2. Click **Share** in the top-right
3. Search for your integration name
4. Click **Invite**

The integration now has access to that page and all its children.

### Step 4: Configure in OpenResponses

1. Open **Settings** in OpenResponses
2. Scroll to **Tools**
3. Find **MCP Server** and enable it
4. Click to expand configuration
5. Enter the following:
   - **Server Label**: `Notion`
   - **Server URL**: `https://api.notion.com/mcp/v1`
   - **Authorization**: Your integration token (e.g., `secret_abc123...`)
   - **Require Approval**: Enable for sensitive operations
   - **Allowed Tools**: Leave empty to allow all tools, or specify specific tools

6. Tap **Save**

### Quick Setup with Preset

For even faster setup:

1. Open **Settings** → **Tools** → **MCP Server**
2. Tap the **Notion (Sample)** preset button
3. Replace the sample authorization token with your actual token
4. Adjust approval and allowed tools settings as needed
5. Tap **Save**

## Using Notion MCP in Conversations

Once configured, you can interact with your Notion workspace naturally:

### Example Prompts

**Search your workspace:**
```
Search my Notion workspace for all pages about "project roadmap"
```

**Create a new page:**
```
Create a new page in my Notion workspace titled "Meeting Notes - Oct 11" 
with a summary of our discussion about the mobile app redesign
```

**Update existing content:**
```
Find the page titled "Q4 Goals" and add a new task: 
"Launch MCP integration by end of month"
```

**Generate documentation:**
```
Read all my project notes from Notion and create a comprehensive 
technical specification document
```

**Build reports:**
```
Search my Notion workspace for all completed tasks this week 
and create a progress report
```

## Available MCP Tools

The Notion MCP server provides the following tools:

### `notion_search`

Search across your Notion workspace.

**Parameters:**
- `query` (string): Search query
- `filter` (object, optional): Filter by page type
- `sort` (object, optional): Sort results

### `notion_get_page`

Retrieve a specific Notion page by ID.

**Parameters:**
- `page_id` (string): The Notion page ID

### `notion_create_page`

Create a new page in your workspace.

**Parameters:**
- `parent` (object): Parent page or database ID
- `properties` (object): Page properties
- `children` (array, optional): Initial page content blocks

### `notion_update_page`

Update an existing page's properties.

**Parameters:**
- `page_id` (string): The page to update
- `properties` (object): Properties to update

### `notion_append_block_children`

Add content blocks to a page.

**Parameters:**
- `block_id` (string): Parent block ID
- `children` (array): Content blocks to append

### `notion_get_database`

Retrieve a database and its schema.

**Parameters:**
- `database_id` (string): The database ID

### `notion_query_database`

Query a database with filters and sorting.

**Parameters:**
- `database_id` (string): The database to query
- `filter` (object, optional): Filter conditions
- `sorts` (array, optional): Sort order

## Approval Workflow

When **Require Approval** is enabled, the AI will request permission before:

- Creating new pages
- Updating existing pages
- Deleting content
- Making bulk changes

You'll see a system message in the chat:

```
🔒 MCP tool 'notion_create_page' on server 'Notion' requires your approval 
before proceeding.

Request ID: req_abc123...
```

**Note**: The approval UI is coming soon. For now, you'll see the notification but won't be able to approve/deny directly in the app.

## Security & Privacy

### Data Flow

1. **OpenResponses** → **OpenAI** → **Notion MCP Server** → **Notion API**
2. Your Notion integration token is stored securely in iOS Keychain
3. The token is only sent to OpenAI's API (never to third parties)
4. OpenAI uses the token to authenticate with Notion's MCP server
5. All communication happens over HTTPS

### Best Practices

1. **Use workspace-specific integrations** — Create separate integrations for different Notion workspaces
2. **Grant minimal permissions** — Only enable read/write permissions you need
3. **Share selectively** — Only share specific pages with your integration, not your entire workspace
4. **Enable approval for sensitive operations** — Turn on "Require Approval" for production workspaces
5. **Rotate tokens periodically** — Generate new integration tokens every few months
6. **Monitor usage** — Check Notion's integration activity log regularly

### Revoking Access

To revoke OpenResponses access to your Notion workspace:

1. Go to [Notion Integrations](https://www.notion.so/my-integrations)
2. Find your integration
3. Click **Settings** → **Delete integration**

Or simply disable the MCP tool in OpenResponses Settings.

## Troubleshooting

### "Failed to list tools from server"

**Possible causes:**
- Invalid server URL
- Network connectivity issues
- Server is temporarily unavailable

**Solutions:**
- Verify the server URL is correct: `https://api.notion.com/mcp/v1`
- Check your internet connection
- Try again in a few minutes

### "Authorization failed"

**Possible causes:**
- Invalid or expired integration token
- Integration doesn't have required permissions

**Solutions:**
- Verify your token starts with `secret_` and is entered correctly
- Regenerate the integration token in Notion
- Check that the integration has Read/Update/Insert permissions enabled

### "Page not found"

**Possible causes:**
- Integration doesn't have access to the page
- Page was deleted or moved
- Incorrect page ID

**Solutions:**
- Share the page with your integration (click Share → invite integration)
- Verify the page exists in your workspace
- Check that you're using the correct page ID or search query

### "Rate limit exceeded"

**Possible causes:**
- Too many requests in a short time
- Notion API rate limits reached

**Solutions:**
- Wait a few minutes before trying again
- Reduce the frequency of requests
- Consider caching frequently accessed data

## Advanced Configuration

### Filtering Available Tools

To restrict which Notion tools the AI can use, specify them in **Allowed Tools**:

```
notion_search,notion_get_page,notion_create_page
```

This prevents the AI from updating or deleting content, only allowing reads and creation.

### Custom MCP Server

If you're hosting your own Notion MCP server:

1. Deploy the server from: https://github.com/makenotion/notion-mcp-server
2. Update the **Server URL** in OpenResponses to your deployment URL
3. Configure authentication as needed
4. Set appropriate approval and tool filtering

## Examples

### Example 1: Search and Summarize

**User:**
```
Search my Notion for pages about "API documentation" and give me a summary
```

**Behind the scenes:**
1. AI calls `notion_search` with query "API documentation"
2. MCP server returns matching pages
3. AI calls `notion_get_page` for top results
4. AI summarizes the content for you

### Example 2: Create Meeting Notes

**User:**
```
Create a new meeting notes page for today's standup. Add attendees: 
Alice, Bob, Charlie. Topics: Sprint planning, Bug triage, Q4 roadmap.
```

**Behind the scenes:**
1. AI calls `notion_create_page` with:
   - Title: "Meeting Notes - Oct 11, 2025"
   - Content blocks with attendees list and topics
2. MCP server creates the page
3. AI confirms with page link

### Example 3: Update Task Status

**User:**
```
Find my "Q4 Tasks" database and mark all tasks assigned to me as "In Progress"
```

**Behind the scenes:**
1. AI calls `notion_search` to find "Q4 Tasks" database
2. AI calls `notion_query_database` filtered by assignee
3. AI calls `notion_update_page` for each matching task
4. If approval is enabled, AI requests permission before updating

## Resources

- **Notion MCP Documentation**: https://developers.notion.com/docs/mcp
- **Notion MCP Server GitHub**: https://github.com/makenotion/notion-mcp-server
- **Model Context Protocol**: https://modelcontextprotocol.io/introduction
- **Notion API Reference**: https://developers.notion.com/reference/intro
- **Notion Integrations**: https://www.notion.so/my-integrations

## Support

For issues with:

- **OpenResponses MCP integration**: Check the app logs in Settings → Advanced
- **Notion MCP server**: Visit the GitHub repository issues
- **Notion API**: Contact Notion support

## What's Next?

- [FILE_MANAGEMENT.md](FILE_MANAGEMENT.md) - Learn about file handling in OpenResponses
- [COMPUTER_USE_INTEGRATION.md](COMPUTER_USE_INTEGRATION.md) - Explore computer use capabilities
- [Tools.md](Tools.md) - Overview of all available tools

---

**Last Updated**: October 11, 2025
