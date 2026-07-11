# Risk Register

This document lists architectural, security, concurrency, and functional risks across the consolidation.

| Risk ID | Source (PRs / Files) | Description | Impact | Mitigation Plan / Resolution | Status |
|---|---|---|---|---|---|
| R-01 | Cluster G: Streaming | Stale async callbacks or tasks mutably updating state after a new streaming session starts. | High | Implemented generation-scoped `currentStreamGeneration: UUID` check inside `MainActor.run` blocks to reject outdated operations. | Mitigated |
| R-02 | Cluster E: Credentials | Plaintext storage of credentials in UserDefaults or persistent prompt configurations. | Critical | Enforced Keychain storage using stable `Prompt.id.uuidString` keys; clear legacy labels and plaintext fields automatically. | Mitigated |
| R-03 | Cluster E: OAuth | OAuth state/CSRF vulnerabilities in callback redirects. | High | Enforced cryptographically secure, single-use `state` parameter validation and unique parameter checks in callback URL query parsing. | Mitigated |
| R-04 | Cluster D: Privacy | URLs/logs containing access tokens, signatures, or user credentials in plaintext. | High | Centralized sensitive URL parameters redaction to swap values with `[REDACTED_SECRET]` in `AppLogger`. | Mitigated |
| R-05 | Cluster C: WebView | Custom URL schemes or redirection allowing bypass of HTTPS policies. | High | Restricted all navigations/redirects/new window targets to `http`, `https`, and `about:blank` schemes in `WebContentView`. | Mitigated |
| R-06 | Cluster B: Date/Formatters | Shared mutable DateFormatter instances causing concurrency races or timezone/locale drift. | Medium | Eliminated mutable `DateFormatter` references; refactored to thread-safe value-styled formatting and static `AppleDateUtilities`. | Mitigated |
