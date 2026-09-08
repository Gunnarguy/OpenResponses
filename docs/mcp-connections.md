# MCP connections in OpenResponses 2.6

Updated September 8, 2026. This document covers the account sign-in redesign added after the original headless discovery work. The older discovery engine remains in use; the connection setup and account model have changed substantially.

## The user experience

Settings → MCP now opens **Connections**, a single account library. The former connector gallery, remote-server sheet and Tools connection entry point lead into this experience. Tools → Connect Apps & Accounts reaches the same library.

1. Search the featured catalog, optionally filter by category, and open a provider.
2. Choose **Connect**. For supported services, the system sign-in sheet opens that provider's own login and consent screen. OpenResponses never asks for the provider password.
3. After a successful callback and token exchange, the account is saved in the device Keychain and enabled for the current chat. A cancelled or invalid callback cannot create a connected account.
4. Under **Your connections**, switch **Use in this chat** on or off independently for each account. Several accounts can be selected together. Switching one off preserves the login.
5. Open an account to rename it, reconnect, discover tools, inspect schemas and annotations, select allowed tools, change approval policy, or disconnect.

An account connection and a successful tool catalog check are different states. Signing in does not call OpenAI or require an OpenAI API key. **Discover Tools** uses the user's OpenAI API account to retrieve definitions without running tools or including chat history. It has a separate data-sharing confirmation and is disabled in offline Demo Mode. Connect and registry search explicitly say **Leave Demo** when needed; browsing the bundled catalog stays offline.

New connections ask for approval before tool calls. Permissions apply to the saved account wherever it is selected. An empty allowed-tools list means all available tools; the interface prevents accidentally interpreting an empty selection as no access. Switch off the account for the chat to disable it. Catalog inspection can retrieve all definitions without changing the account's allowed-tools policy.

Disconnect removes the local record and prevents pending refresh work from restoring it. It does **not** claim to revoke the provider's consent grant. The interface directs users to the provider's connected-app settings for grant revocation.

## Catalog and availability

The bundled catalog has **44 entries**, covering productivity, design, development, data, cloud, communication, files and commerce. Some services expose several distinct remote endpoints, so entries are not a count of unique vendors. Live search of the public MCP Registry extends the catalog without requiring an app update.

Registration was checked against real provider metadata and registration endpoints on September 8. **19 entries accepted the native OpenResponses callback**. This proves registration compatibility, not completion of an account login, workspace permission, tool discovery, or write action. The running iOS app also reached Notion's actual account-login screen through `ASWebAuthenticationSession`.

| Availability | Entries |
| --- | --- |
| Native registration accepted | Notion, Linear, Atlassian, Canva, Todoist, Miro, Stripe, PayPal, Webflow, Supabase, Neon, PostHog, Sentry, Amplitude, Cloudflare Workers, Observability, Builds, Browser Rendering and Radar |
| Public server, no account needed | DeepWiki and Cloudflare Documentation |
| Provider approval or registered application required | Figma, Asana, HubSpot, Box, Slack; Zoom Workplace, Meetings, Docs, Tasks, Team Chat and Whiteboard |
| Current native callback rejected during registration | monday.com, Airtable, Intercom and Vercel |
| OpenAI-maintained connector IDs requiring application-owned provider OAuth setup | Dropbox, Google Drive, SharePoint, Gmail, Outlook Email, Google Calendar, Outlook Calendar and Microsoft Teams |

The last three groups display **Provider setup required**. They are not presented as completed integrations or asked to paste OAuth access tokens. Figma documents a client allowlist; Asana v2, HubSpot, Box and Slack require app configuration. Zoom metadata does not advertise dynamic registration. Several other providers require a different approved redirect arrangement. The older Asana `/sse` address is replaced by its current `/v2/mcp` endpoint.

These restrictions are a real remaining distribution dependency if the release is expected to offer sign-in for every listed provider. Completing them requires OpenResponses' own developer registrations, provider approvals where applicable, an approved HTTPS callback arrangement for providers rejecting private-use schemes, and a server-owned OAuth component for confidential clients. Shared app client secrets must not be embedded in the iOS bundle. Existing ChatGPT/Codex registrations and client identities must not be reused as OpenResponses registrations.

The sanitized [provider compatibility evidence](releases/v2.6/MCPOAuthCompatibility.json) records metadata and registration outcomes. Client IDs and generated client secrets from the probes are excluded from the repository and documentation. No account authorization or provider data mutation was performed by those probes.

## Native authorization implementation

`MCPAuthorization.swift` implements the authorization-code flow with PKCE:

- HTTPS protected-resource metadata discovery, followed by authorization-server metadata or OpenID Connect discovery. Path-specific issuers use the corresponding well-known paths.
- Compatibility with the older MCP same-origin authorization-metadata format used by Atlassian and Intercom. Token and authorization endpoints are still discovered from metadata, never invented from URL guesses.
- Resource matching checks the provider host and path boundary. Root URLs with or without a trailing slash are equivalent; `/mcp-evil` cannot impersonate `/mcp`.
- Advertised S256 support is required. State and verifier use system-generated random bytes; only the S256 challenge goes to the authorization endpoint.
- Dynamic client registration requests the native application type and the callback `openresponses://mcp/oauth/callback`. Returned callback and token-authentication method must match the request.
- Public clients are preferred. Providers that issue an installation-specific client secret can use `client_secret_post` or `client_secret_basic`; that generated credential is saved in the protected account record. This is distinct from bundling a shared confidential-client secret.
- The requested resource is included in authorization and token requests. Code exchange includes the verifier and exact redirect URI. Refresh responses preserve a previous refresh token if the provider omits a replacement.
- Callback scheme, host, path, state and optional issuer are verified. Duplicate callback fields, wrong state, an unexpected issuer, embedded credentials or fragments fail the connection.
- Metadata and token transport uses ephemeral sessions without cookies or URL caching, refuses redirects, limits response size to 1 MiB and enforces request/resource timeouts. The browser login uses the system's browser cookies so existing provider sessions can be reused.
- Errors shown to users are locally defined and do not echo arbitrary authorization-server diagnostics or tokens.

`MCPWebAuthentication.swift` owns and cancels the system browser session. Each attempt has its own continuation and generation; callbacks cannot complete a newer attempt. The app's Info.plist registers the callback scheme in both build configurations.

The client currently implements dynamic registration and the older same-origin metadata compatibility path. It does not advertise Client ID Metadata Documents, an enterprise registration broker, external-account SSO provisioning, or universal provider admission as implemented features.

## Account storage and chat execution

`MCPConnectionStore.swift` commits account metadata and credentials together as a versioned, device-only Keychain item. Published SwiftUI account records contain names, endpoints, IDs, permissions and status, with **no access token, refresh token or client secret**. Prompt settings contain selected account UUIDs rather than credential values.

A failed write preserves the previous account record. An unreadable or unknown-version archive is not overwritten with an empty library. New connections are published only after secure storage succeeds. Reconnecting retains the account UUID, name and permissions; late callbacks cannot resurrect deleted accounts or overwrite a newer authorization.

Expiring credentials refresh ahead of expiry, with concurrent callers sharing one refresh. Rotation is committed atomically. An invalid grant marks the existing record as needing sign-in instead of silently deleting it. A disconnect cancels its refresh work. Policy and name edits remain intact if a token refresh completes at the same time.

Each selected account produces a distinct Responses `mcp` tool with a stable opaque `server_label`, its own endpoint or connector ID, its own authorization, approval policy and allowed tools. Initial sends, function continuations and MCP approval continuations prepare credentials before serialization. Native managed HTTP/SSE/WebSocket transports refresh credentials at their send boundary, matching both account label and endpoint; a substituted endpoint or deleted account cannot receive/reuse a stored token. Raw API Workbench requests remain literal and do not automatically acquire account-library credentials.

Approval cards resolve opaque labels to account names. When multiple accounts are selected and an event omits its server identity, fallback formatting avoids attributing it to whichever server happened to run last.

## Migration and compatibility

A prompt with no `mcpConnectionIDs` field keeps its legacy request behavior until migration. Opening Connections imports its saved remote or OpenAI connector configuration, including approval policy, allowed tools and headers. The import is idempotent for that prompt. After the secure record is saved, the prompt references its account ID and clears any inline header value. Existing legacy Keychain entries are retained so other saved configurations are not destructively rewritten.

An explicitly empty account-ID array means the prompt uses the account library with no selected accounts; it does not fall back to a previously configured remote. Existing direct Notion integration keys are still manageable under **Existing Notion integration**. New Notion connections go through hosted MCP account sign-in. The direct Notion API integration and hosted Notion MCP have different credentials and are not interchangeable.

Custom servers default to **Account sign-in**. Public servers and explicitly supported API-key authentication remain advanced choices. Hosted Notion rejects the API-key option. The app removes the old OAuth Playground/token-copying tutorials and placeholder community-server addresses from the normal connection screens.

## Registry behavior

Registry search uses the public `registry.modelcontextprotocol.io/v0.1/servers` endpoint with pagination. It includes active remote HTTPS servers supporting Streamable HTTP or SSE. It excludes local stdio packages, templated credential URLs, unsafe URLs, credential query parameters, duplicate endpoint URLs and inactive entries. Required-header templates are not advertised as ready account sign-in.

The registry is a discovery service, not a guarantee that a listing is safe or endorsed by its named vendor. The UI shows the registry publisher and actual server host. Untrusted descriptions are bounded; documentation links must pass HTTPS validation. Changing the query or leaving the screen cancels the search, and repeating pagination cursors stop further pagination.

## Validation boundary

The regression suite covers the PKCE reference vector, callback tampering, issuer/resource boundaries, current and older discovery, dynamic registration validation, code exchange, token rotation, invalid-grant handling, atomic vault writes, refresh coalescing, disconnect races, distinct multi-account payloads, endpoint substitution, legacy migration, registry filtering and tool-policy preservation.

Live evidence proves the registered callback compatibility and the Notion login handoff. Successful private-account consent, a real refresh cycle for each intended provider account, and provider-specific tool reads/writes still need account-level checks. See the [release validation ledger](releases/v2.6/Validation.md) for exact suite and device evidence.

## Primary references

- [MCP authorization specification](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)
- [Notion MCP client implementation](https://developers.notion.com/guides/mcp/build-mcp-client)
- [Linear MCP](https://linear.app/docs/mcp)
- [Asana v2 client requirements](https://developers.asana.com/docs/connecting-mcp-clients-to-asanas-v2-server)
- [Figma remote MCP setup](https://developers.figma.com/docs/figma-mcp-server/remote-server-installation/)
- [HubSpot remote MCP integration](https://developers.hubspot.com/docs/apps/developer-platform/build-apps/integrate-with-the-remote-hubspot-mcp-server)
- [Box MCP setup](https://developer.box.com/guides/box-mcp/setup)
- [Slack MCP server](https://docs.slack.dev/ai/slack-mcp-server)
- [Supabase MCP](https://supabase.com/docs/guides/getting-started/mcp)
- [OpenAI MCP and connector tools](https://developers.openai.com/api/docs/guides/tools-connectors-mcp)
