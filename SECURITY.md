# Security Policy and Secrets Management

Last updated: 2026-09-08 (v2.6 implementation clarification)

OpenResponses is designed with security and credential privacy as first-class architectural constraints. As a native iOS and macOS playground designed for prompt engineers and software developers, OpenResponses implements direct API connections without proxy servers. This threat model details our local storage boundaries, API key handling protocols, release safeguards, and incident reporting.

---

## 1. Supported Versions & Lifecycle Status

We actively patch security vulnerabilities for the main branch and official tagged releases.

| Version | Status | Notes |
| :--- | :--- | :--- |
| **v2.6 source** | **Current development candidate** | See the release dossier for tested source and delivery status. |
| **v2.5** | **Released in ASC** | Uploaded build 4; verified September 8. |
| **Earlier versions** | **Historical** | No separate maintenance commitment is established by this version table. |

---

## 2. Secrets Storage Model

### iOS Keychain
OpenResponses relies on the iOS Keychain generic-password storage (`SecItem` APIs, device-only accessibility after first unlock) to persist sensitive credentials. The application utilizes a dedicated singleton class `KeychainService` (`Core/Services/KeychainService.swift`) to add, read, and remove keys.

The following credentials use Keychain storage in the app. Request-time use necessarily reads them into memory; this is not a claim that an API token itself is a Secure Enclave cryptographic key:
1. `openAIKey`: Your OpenAI API key (`sk-...`).
2. `notionApiKey`: The existing direct Notion integration credential; separate from hosted Notion MCP OAuth.
3. `mcp_manual_[label]`: HTTP header JSON payloads containing credentials/keys for custom MCP servers.
4. `mcp_auth_[label]` & `mcp_connector_[id]`: Legacy authentication tokens for third-party connector systems.
5. `mcpConnections.v1`: Atomic account metadata, OAuth access/refresh credentials and per-install registration details. Published UI records contain no secrets.
6. `apiWorkbenchDraft.v1`: Recoverable Workbench request text and selector state, which may contain sensitive request content.

Native MCP sign-in uses the system browser, authorization-code/PKCE S256, exact callback state/issuer validation and redirect-refusing bounded token transport. See [MCP connection security and remaining provider setup](docs/mcp-connections.md). Disconnect deletes the local account; provider grant revocation is a separate provider-account operation.

### UserDefaults Isolation
Standard `UserDefaults` (`@AppStorage` property wrappers) are strictly limited to non-sensitive preferences:
- Model selections (e.g., `gpt-5.5`, `o3-mini`)
- Reasoning effort levels (`low`, `medium`, `high`)
- Temperature, top-p, and parallel tool call toggles
- UI preferences (e.g., dark mode settings, diagnostic layout panels)

### Retroactive Migration Hook
On application launch, `KeychainService.shared.migrateApiKeyFromUserDefaults()` executes. If legacy debug builds saved the OpenAI API key to `UserDefaults` (as `openAIAPIKey`), the helper reads it, writes it securely to the Keychain, and immediately removes it from `UserDefaults` to secure the credentials.

---

## 3. Network Boundary & API Key Handling

- **No Intermediate Proxies:** The device contacts configured services through HTTPS or secure WebSockets. OpenAI-hosted tools can make further service connections. There are no developer-owned proxy servers, databases, or middle-tier logging layers.
- **Header Injection:** API keys and access tokens are retrieved from the Keychain at request execution time and injected dynamically into HTTP headers (e.g., `Authorization: Bearer <key>`). They are present in memory during use and transmitted to the relevant service for authentication. OpenAI-hosted MCP can also receive configured server authentication in the request body. Review raw exports before sharing them.

---

## 4. Local Storage Risks & Sandbox Isolation

- **App Sandboxing:** The iOS sandboxing framework limits file access. Conversation histories (stored as JSON structures by `ConversationStorageService`) are written to the app's sandboxed document directory (`FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)`).
- **Security-Scoped Bookmarks:** When attaching local files or directories, the application uses Apple’s security-scoped bookmarks. This allows the app to retain file read permissions across launches without requiring system-wide file access.
- **Local Logs Sanitation:** Logs created by `AppLogger` are transient (stored in-memory or written to local console logs). They do not leave the device unless the user manually exports them for debugging.

---

## 5. Logging Policy

- **No Credential Logging:** The logging singleton `AppLogger` enforces a strict policy: raw API keys, Notion tokens, and request authorization headers are filtered and must never be written to console outputs.
- **Scope:** Redaction is a tested, targeted defense, not proof that every legacy diagnostic/export surface can never contain sensitive information. The [2.6 technical record](docs/releases/v2.6/TechnicalChanges.md) documents that boundary.
- **Plaintext Masking:** During network inspections (using the in-app Request Inspector), sensitive keys are redacted from the request headers using `[REDACTED_SECRET]` indicators in the UI view.

---

## 6. Release-Build Safeguards

To prevent accidental check-ins of testing tokens, the repository includes two verification utilities:
1. **Hardcoded Secret Scanner (`scripts/secret_scan.py`):**
   A Python script that scans Swift files, plists, JSONs, shell scripts, and configurations for exposed secret prefixes (such as `sk-` or common key variables). It runs during local test phases.
2. **Preflight Compliance Check (`scripts/preflight_check.sh`):**
   This script runs before building a release candidate. It verifies that:
   - No hardcoded API keys are present.
   - All required iOS privacy description keys (e.g., Calendar, Reminders, Contacts) are declared in `Info.plist`.
   - All unit test targets compile and pass successfully.

---

## 7. Vulnerability Reporting Process

If you discover a security vulnerability or credential exposure:
1. **Do Not File a Public Issue:** Please do not open a public GitHub issue for security disclosures.
2. **Report Privately:** Email details to [security@gunnarguy.com](mailto:security@gunnarguy.com). If possible, include code snippets or steps to reproduce the issue.
3. **Response SLA:** We will acknowledge receipt of your vulnerability report within 48 hours and provide a remediation timeline.

---

## 8. Security Checklist for Future Changes

Developers and autonomous coding agents contributing code modifications must satisfy:
- [ ] No API keys, credentials, or client secrets are hardcoded.
- [ ] Any new sensitive token uses reviewed Keychain storage with atomic updates and explicit failure handling.
- [ ] No telemetry or network logs print raw request header contents.
- [ ] Run `python3 scripts/secret_scan.py` and verify it exits with `0`.
- [ ] If local WebView automations are modified, verify they restrict script injections and frame-loading to validated target URLs.
