# MCP discovery

> The September 8 account sign-in redesign supersedes the setup/migration UI described in this earlier milestone. See [MCP connections](mcp-connections.md) for the current OAuth flow, account library, catalog and provider limitations. The headless discovery transport and historical probes below remain relevant.


> Part of the [complete v2.6 release dossier](releases/v2.6/README.md). Test counts below describe this milestone; the final implementation total is **265**, recorded in the [validation ledger](releases/v2.6/Validation.md). [Live ASC status](releases/v2.6/ASCStatus.md) is tracked separately.


The app uses OpenAI-hosted MCP through the Responses API. It does not run a local MCP process, launch a browser for discovery, or implement a second MCP transport client. Provider OAuth registration, consent and token refresh remain separate from tool discovery.

## Behavior

- Normal chat lets Responses discover the configured server's tools during the actual turn. The former extra diagnostic model turn and label-only 24-hour health gate are removed. Hosted tool turns are not transparently replayed after a transport failure because a remote write may already have completed.
- Settings → MCP → Discover Tools and remote setup sheets share one service and catalog UI. The check sends only the configured MCP tool, a fixed discovery directive, `tool_choice: none`, `require_approval: always`, `store: false`, and a 32-token output cap on `gpt-5.6-luna`. Chat instructions, history, attachments, experimental settings and other tools are excluded. Discovery uses the user's OpenAI API account.
- Only a completed `mcp_list_tools` output item or a catalog in the terminal response counts as success. Lifecycle events without schemas do not mean zero tools. A genuinely empty array is displayed as an empty catalog, not a timeout. Unexpected tool calls or approval requests fail the check without approval.
- The UI respects the existing offline Demo Mode and first-send data-sharing consent. It supports refresh, cancellation, searchable tool names/descriptions, input schemas, server annotations, last-check time and allowed-tools filtering. Editing configuration clears the displayed result. Saving configuration does not claim a verified connection.

## Reliability and credentials

A 35-second wall-clock deadline cancels the underlying HTTP request, including when the server sends no events. One transient availability retry is allowed within that deadline. Authentication failures, rate limits and malformed catalogs are not automatically retried. Identical concurrent requests share a flight; cancelling one consumer leaves other consumers running, and cancelling the last consumer closes the connection.

Successful catalogs are cached in memory for five minutes, with a maximum of 16 entries. The key hashes the endpoint/connector, label, credentials, allowed tools and OpenAI account. Explicit refresh invalidates the prior success before making a request. The cache stores no credential values and is not used as authorization or as a substitute for the server's current chat tool policy.

Draft checks read credentials without migrating or writing Keychain entries. Draft overrides, including an explicitly empty token, never fall back to saved credentials. Save writes the new server's credentials to the active prompt's ID, replacing the prior server's values. API-key headers preserve their raw value; bearer tokens use OpenAI's authorization field unless the existing header-only option is selected. Header validation rejects control characters and duplicate names. Errors are classified without displaying arbitrary remote text that could echo credentials.

The dedicated ephemeral HTTP client disables cookies/cache and refuses redirects. SSE decoding supports comments, CRLF, multi-line data and `[DONE]`; it bounds individual events to 4 MiB, the stream to 12 MiB, buffered events to 64, and catalogs to 2,000 distinct tools. Invalid, duplicate or missing tool schemas fail explicitly.

The app no longer invents or forwards MCP session/protocol transport headers. OpenAI owns protocol negotiation with the remote server. Older MCP revisions used server-issued session IDs; the July 2026 revision removed protocol sessions altogether. Supporting that revision on a particular remote server depends on OpenAI's hosted MCP client and that server, not an app-supplied version header.

## Verification

- Full simulator unit suite: 221 tests passed, including 17 discovery and chat lifecycle regressions.
- Live public DeepWiki discovery with tool execution disabled: three tools returned in 2.37 seconds.
- The actual Swift discovery service/transport, compiled into a standalone validation harness with a private credential loader: three tools returned in 1.48 seconds; a second call matched the snapshot and made no second HTTP request.
- Simulator Settings verified: discovery enables for a public HTTPS draft, reports a missing OpenAI key immediately, and provides Retry Discovery without saving credentials.
- Signed physical-device build and installation succeeded on Gunnar’s Hand Extension. Automatic launch was blocked by the locked phone. Private provider OAuth and every third-party server have not been exercised; public discovery does not prove those account-specific paths.

## References

- [OpenAI MCP and connectors](https://developers.openai.com/api/docs/guides/tools-connectors-mcp)
- [MCP July 2026 specification release](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
