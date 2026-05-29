# OpenResponses Privacy Overview

Last updated: 2026-05-29

OpenResponses is a native iOS client for the OpenAI Responses API. The app is built with a local-first design philosophy: your documents, API keys, and conversation logs are persisted locally and never routed through any developer-owned servers. This document provides a transparent map of our data processing pipeline, device permissions, and integrations.

---

## On-Device Storage Boundaries

The following information is persisted locally inside the sandboxed iOS environment:
* **API Credentials:** Keys and connection tokens (such as OpenAI API keys and Notion tokens) reside strictly within the secure iOS Keychain. Standard `UserDefaults` are never used for sensitive tokens.
* **Local Conversation History:** Saved prompt templates, message feeds, and tool outputs are stored locally on-device. No data is stored in iCloud or cloud sync networks unless you explicitly opt in to the cloud-backed history.
* **Security-Scoped Bookmarks:** When attaching local documents or folder locations, the app generates security-scoped bookmarks stored on-device to retain access permission across launches.
* **Local Diagnostic Logs:** The logs displayed in the developer log console are transient, saved in memory and local file logs, and never exported unless manually triggered by the user.

---

## Data Sent Off-Device

To perform completions and run tools, OpenResponses contacts external endpoints directly over secure HTTPS. We do not use intermediary backend servers. Below is the data destinations map:

| Destination Service | Exact Data Shared | Purpose of Transmission | User Opt-Out / Controls |
| :--- | :--- | :--- | :--- |
| **OpenAI Responses API** | Prompt messages, active settings parameters, uploaded file data, and tool definitions. | Process natural language inputs and stream completed text or reasoning results. | Complete control over model parameters. The first live request is gated behind an explicit permission notice. |
| **OpenAI Embeddings API** | Text blocks or query text from document attachments. | Create semantic vector representations for file search. | Can be disabled by turning off File Search capabilities in settings. |
| **Notion API** *(optional)* | Notion Workspace access tokens and database schema fields. | Allow the assistant to query, create, or update Notion database records. | Disabled by default. Can be disconnected or revoked in settings at any time. |
| **Local Network Bridge** *(optional)* | Screen captures (screenshots), mouse clicks, mouse scroll values, and system commands. | Automate user actions via the local `computer` or `computer_use_preview` tools. | Gated by a local network permission prompt and an explicit step-by-step UI approval dialog. |

---

## Exclusions & SDK Declarations

* **Third-Party Tracking:** OpenResponses does **not** integrate third-party analytics SDKs, user behavior tracking trackers, or diagnostic reporting networks (like Firebase, Mixpanel, or Amplitude).
* **Advertising:** The application does **not** include mobile advertising networks, user identification tokens, or ad-delivery SDKs.
* **Crash Reports:** Crash diagnostics are managed natively by Apple's opt-in system reporting. These reports contain stack traces and do **not** include API keys or message contents.

---

## In-App Approvals & Revocation

### The First-Send Consent Notice
Prior to executing the first live connection to OpenAI, the application presents a data-sharing notice detailing that inputs are sent to OpenAI and requires a tap of **Allow & Send**. No network payloads are sent before this confirmation. You can reset this notice from **Settings → General**.

### Setting Resets
You can completely reset the application without deleting it from your device. Under **Settings → General**, tapping **Reset All Settings** will:
1. Erase all Keychain-backed credentials.
2. Purge local history databases.
3. Revoke folder and file bookmark consents.
4. Return the app to the onboarding phase.

---

## Contact
For privacy inquiries or support, email [support@gunnarguy.com](mailto:support@gunnarguy.com).
