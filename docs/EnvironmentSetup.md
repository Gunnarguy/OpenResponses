# Environment Setup Guide

This document describes how to configure API keys and secrets for the OpenResponses app during development and testing.

## Overview

OpenResponses requires several API keys and secrets to function. These credentials are:

- **Never committed to the repository** (protected by `.gitignore`)
- **Stored securely in the iOS Keychain** at runtime
- **Managed via a user-facing settings interface** in the app

## Required Credentials

### 1. OpenAI API Key (Required)

- **Purpose:** Authenticate requests to the OpenAI Responses API
- **Keychain Key:** `openAIKey`
- **Setup:** Users configure this key through the app's Settings screen on first launch
- **Format:** `sk-proj-...` (OpenAI project key)

### 2. Notion Integration Token (Optional)

- **Purpose:** Authenticate with Notion MCP server for document access
- **Keychain Key:** `notionApiKey`
- **Setup:** Optional; configured in Settings → MCP Connectors if Notion integration is needed
- **Format:** `ntn_...` or `secret_...`

### 3. MCP Server Authentication (Optional)

- **Purpose:** Authenticate with remote Model Context Protocol (MCP) servers
- **Keychain Keys:** `mcp_manual_<label>` or `mcp_connector_<connector_id>`
- **Setup:** Configured per-server in Settings → MCP Connectors
- **Format:** Bearer tokens or custom JSON headers

### 4. Development Environment Variables (Developer Only)

- **Purpose:** Support external MCP servers during local development
- **Location:** `~/.envrc` (loaded by `direnv`)
- **Variables:**
  - `GITHUB_TOKEN` - GitHub Personal Access Token
  - `PINECONE_API_KEY` - Pinecone vector database key
  - `OPENAI_API_KEY` - Development OpenAI key (for testing external MCP servers)
  - `NOTION_API_KEY` - Notion integration token (for self-hosted MCP)

**Important:** These environment variables are **not** used by the iOS app itself. They support external services and MCP servers during development only.

## Security Best Practices

### .gitignore Protection

The following patterns are excluded from version control:

```gitignore
*.env
.env
.envrc
test.env
config.plist
secrets.plist
AuthKey_*.p8
*.mobileprovision
```

### Keychain Storage

All sensitive credentials entered by users are stored in the iOS Keychain via `KeychainService.swift`:

- Keys are namespaced (e.g., `openAIKey`, `mcp_manual_<label>`)
- Values are encrypted by the system
- Data is tied to the app's bundle identifier and remains isolated

### Logging Safeguards

The app uses `AppLogger.swift` and `AnalyticsService.swift` with production-safe logging:

- **Release builds:** Network request/response bodies are omitted; sensitive headers redacted
- **Debug builds:** Full logging available via user toggle; still redacts Authorization headers
- API keys are always replaced with `Bearer sk-***REDACTED***` in logs

### Code Review Checklist

Before committing code that handles credentials:

1. Verify no hardcoded API keys or tokens exist in source files
2. Ensure new credential types are added to `KeychainService` keys
3. Confirm `.gitignore` patterns cover any new secret file types
4. Check that logging code redacts sensitive headers and bodies

## Developer Setup (First Time)

1. **Clone the repository**

   ```bash
   git clone https://github.com/Gunnarguy/OpenResponses.git
   cd OpenResponses
   ```

2. **Configure external services (if using MCP servers)**

   ```bash
   # Create or edit ~/.envrc
   export GITHUB_TOKEN="github_pat_..."
   export PINECONE_API_KEY="pcsk_..."
   export OPENAI_API_KEY="sk-proj-..."
   export NOTION_API_KEY="ntn_..."
   
   # Allow direnv to load the file
   direnv allow
   ```

3. **Build and run the app in Xcode**

   - Open `OpenResponses.xcodeproj`
   - Build for iOS Simulator or Device
   - On first launch, the app will prompt for your OpenAI API key
   - Enter the key in Settings; it will be saved to the Keychain

4. **Verify no secrets are staged**

   ```bash
   git status
   # Confirm test.env, .envrc, and other secret files are not listed
   ```

## Testing & CI Considerations

- **Unit/UI Tests:** Do not require real API keys; mock `KeychainService` or use test keys
- **TestFlight Builds:** Users must configure their own OpenAI API key after installation
- **App Store Release:** No embedded secrets; users provide all credentials at runtime

## Troubleshooting

### "API Key Missing" Error

- **Solution:** Open Settings, enter a valid OpenAI API key, and save

### MCP Server Connection Fails

- **Solution:** Verify the MCP server URL and authentication token in Settings → MCP Connectors

### "Notion Integration Token Required"

- **Solution:** If using Notion tools, add a Notion integration token in Settings → MCP Connectors → Notion

### Accidental Secret Commit

If a secret is accidentally committed:

1. **Rotate the credential immediately** (generate a new key/token)
2. Remove it from git history:

   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch <file>" \
     --prune-empty --tag-name-filter cat -- --all
   ```

3. Force push to remote (coordinate with team)
4. Update `.gitignore` to prevent recurrence

## Support

For security concerns or questions about credential management, contact the development team or open an issue in the repository.

---

**Last Updated:** November 8, 2025  
**Maintainer:** OpenResponses Team
