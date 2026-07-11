# Risk Register

This document lists architectural, security, concurrency, and functional risks across the consolidation.

| Risk ID | Source (PRs / Files) | Description | Impact | Mitigation Plan | Status |
|---|---|---|---|---|---|
| R-01 | Cluster G: Streaming | Stale async callbacks or tasks mutably updating state after a new streaming session starts. | High | Implement generation-scoped `StreamingSessionID` to reject outdated operations. | Open |
| R-02 | Cluster E: Credentials | Plaintext storage of credentials in UserDefaults or persistent prompt configurations. | Critical | Enforce Keychain storage using stable identifiers; restrict prompt representation to configuration only. | Open |
| R-03 | Cluster E: OAuth | OAuth state/CSRF vulnerabilities in callback redirects. | High | Enforce cryptographically secure, single-use `state` parameter validation. | Open |
| R-04 | Cluster D: Privacy | URLs/logs containing access tokens, signatures, or user credentials in plaintext. | High | Enforce strict URL parameter redaction fallback to a safe URL path structure. | Open |
| R-05 | Cluster C: WebView | Custom URL schemes or redirection allowing bypass of HTTPS policies. | High | Centralize policy enforcement inside WKNavigationDelegate boundaries. | Open |
| R-06 | Cluster B: Date/Formatters | Shared mutable DateFormatter instances causing concurrency races or timezone/locale drift. | Medium | Use modern, value-based Date.FormatStyle or isolate formatters safely. | Open |
