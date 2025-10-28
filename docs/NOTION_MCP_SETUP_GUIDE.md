# Notion MCP Quick Start (Single Working Method)

This guide is the fastest path to a working MCP connection with Notion in OpenResponses. It uses the official Notion‑hosted MCP server and requires no servers or Docker.

Focus: Paste your Notion Integration Secret, share at least one Notion page with that integration, and tap “Test MCP Connection.”

Last Updated: October 25, 2025

---

## One Working Method: Official Notion‑Hosted MCP

OpenResponses is locked to the official Notion MCP endpoint and a compliant auth configuration:
- Endpoint: https://mcp.notion.com/mcp
- Auth: Top‑level authorization only (OpenAI Responses API rejects sending both a top‑level `authorization` parameter and an `Authorization` header)
- Notion-Version: 2022-06-28 (auto-added)

You only need to provide a valid Notion Integration Secret and share at least one page/database with that integration.

### Step 1 — Create a Notion Integration and Copy the Secret
1) Go to https://www.notion.so/profile/integrations
2) Click + New integration
3) Choose a name (e.g. “OpenResponses MCP”)
4) Pick the workspace to connect
5) Capabilities (recommended):
   - Read content
   - Update content
   - Insert content
6) Click Submit
7) Copy the Integration Secret. It should start with:
   - ntn_… (newer tokens), or
   - secret_… (older tokens)

Important:
- Do NOT include “Bearer” when pasting the secret in OpenResponses.
- If your string does not start with ntn_ or secret_, it is not a Notion integration token.

### Step 2 — Share Content with the Integration
Your integration can only access content you explicitly share with it.

For each page or database you want available to AI:
1) Open the page/database in Notion
2) Click “…” (three dots) → “Add connections”
3) Select your integration (e.g. “OpenResponses MCP”)

Repeat for all content you want to expose.

### Step 3 — Configure OpenResponses
1) Open the OpenResponses app → Settings → MCP Configuration → Use Template
2) Choose Notion MCP (Official)
   - Server Label: notion-mcp-official (locked)
   - Server URL: https://mcp.notion.com/mcp (locked)
3) Paste your Integration Secret (the ntn_… or secret_… value; no “Bearer”)
4) Save
5) Tap Test MCP Connection
   - The app runs a quick Notion preflight using GET /v1/users/me
   - Then it triggers MCP tool listing

If everything is correct, you’ll see streaming events showing tools were listed.

---

## Troubleshooting 401 Unauthorized

If you see “Notion token unauthorized (HTTP 401)”:

1) Check the token format
   - It must start with ntn_ or secret_
   - If it doesn’t, generate a Notion integration and copy its Integration Secret (without spaces)
   - Do not paste anything labeled “OAuth code”, “client secret”, or any random string

2) Re‑copy your secret from Notion and paste again
   - Make sure there are no leading/trailing spaces
   - Do NOT add Bearer yourself (the app normalizes this for you)

3) Verify with curl (optional but definitive)
   Replace YOUR_TOKEN below and run:
   ```bash
   curl -s -i \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Notion-Version: 2022-06-28" \
     https://api.notion.com/v1/users/me
   ```
   Expect HTTP/1.1 200 OK. If you get 401 Unauthorized, the token is invalid or revoked.

4) Ensure pages are shared with the integration
   - Not shared = Not accessible, and some servers may reject tool discovery
   - Add connections → pick your integration

5) The app’s auth is API‑compliant
   - OpenResponses sends the token as a top‑level authorization value (required by OpenAI Responses API when using MCP)
   - It does NOT send an `Authorization` header simultaneously (doing both causes a 400)
   - The `Notion-Version: 2022-06-28` header is auto‑added for Notion endpoints

If you’ve confirmed the token returns 200 via curl and shared content, re-test in OpenResponses.

---

## What You Should See When It Works

- In OpenResponses logs you’ll see:
  - “Prepared MCP header payload … keys: Notion‑Version, Authorization”
  - “Notion token preflight succeeded (200)”
  - A streaming “mcp_list_tools” event and the tools being retrieved

- Typical Notion tools available include:
  - notion_search
  - notion_fetch
  - notion_create_pages
  - notion_update_page
  - notion_create_database
  - notion_get_users
  - notion_get_self
  (Exact list may vary)

---

## FAQ

- Do I need to type “Bearer”?
  - No. Paste just the raw token (ntn_… or secret_…). The app normalizes it.

- Where is my token stored?
  - In the Apple Keychain via secure storage.

- Do I need to allow specific tools?
  - Leave “Allowed Tools” blank for ubiquitous access.

- Do I need to tweak approval settings?
  - The “Require Approval” flow is locked for the official path to keep the One Method frictionless. For production, you can re-enable stricter approval in a future update.

---

## Advanced (Optional): Self‑Hosted Notion MCP

The single supported method in-app is the official Notion server. If you insist on self‑hosting, here’s a minimal outline (unsupported path in the UI):

1) Run Docker
   ```bash
   docker run -d \
     --name notion-mcp \
     --restart unless-stopped \
     -p 8080:3000 \
     -e NOTION_TOKEN=<YOUR_NOTION_TOKEN> \
     mcp/notion \
     notion-mcp-server --transport http --port 3000
   ```
2) Get the server’s bearer token
   ```bash
   docker logs notion-mcp | grep "Bearer token"
   ```
3) Expose a public URL (e.g., ngrok)
   ```bash
   ngrok http 8080
   ```
4) In OpenResponses (future/advanced flow):
   - Set server URL to your host’s /mcp
   - Use the server’s bearer token (not your Notion token)
   - Ensure your hosting allows application‑layer Authorization

Note: Self‑hosting requires extra network/IAM setup and is not part of the single working method enforced in the app.

---

## Summary

- One working method: Official Notion MCP at https://mcp.notion.com/mcp
- Paste a valid Notion Integration Secret (ntn_… or secret_…)
- Share at least one page/database with that integration
- Tap “Test MCP Connection” to validate (preflight + tools list)

If you hit 401:
- Verify the token prefix (ntn_/secret_)
- Re-copy and paste without “Bearer”
- Confirm 200 via `curl /v1/users/me`
- Share content with the integration

Once preflight returns 200 and content is shared, the MCP tool list should load and you can “just call it” in chat.
