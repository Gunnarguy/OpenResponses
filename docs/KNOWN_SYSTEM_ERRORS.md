# Known System & Sandbox Errors

This document catalogs system-level errors and warnings that appear in the console logs during normal app operation. These errors are generally benign and do not indicate bugs in the OpenResponses codebase unless they cause user-facing issues.

## Overview

When running iOS/iPadOS applications, especially in the Simulator or in sandboxed environments, you may see various system-level errors in the console. Most of these are framework-level issues, sandbox restrictions, or initialization race conditions that do not affect app functionality.

## Error Categories

### 1. WebKit/WebView Initialization

**Symptoms:**
- `GPU process took X.X seconds to launch`
- `WebContent process took X.X seconds to launch`
- `Could not create a sandbox extension for '/var/containers/Bundle/Application/.../OpenResponses.app'`

**Cause:**  
These are performance/initialization logs from WebKit processes. The ComputerService uses a WKWebView for the computer-use feature, and WebKit spawns multiple processes (GPU, WebContent, Networking) with strict sandboxing.

**Impact:** None - these are informational logs about process launch times and sandbox initialization.

**Action Required:** None, unless WebView fails to appear or computer-use feature is broken.

---

### 2. Accessibility & Core Animation Errors

**Symptoms:**
- `Could not register system wide server: -25204`
- `_AXAddToElementCache was called even though the element was in the cache`
- `Service "com.apple.CARenderServer" failed bootstrap look up (1) - (os/kern) invalid address`
- `Failed to initialize application environment context`

**Cause:**  
WebKit tries to register accessibility services and Core Animation rendering contexts. In sandboxed/simulator environments, these services may not be available or may have permission restrictions.

**Impact:** None - the app's UI and rendering work correctly despite these errors.

**Action Required:** None, unless you see actual UI rendering problems or accessibility issues.

---

### 3. LaunchServices & User Management Errors

**Symptoms:**
- `personaAttributesForPersonaType for type:0 failed with error ... connection to service named com.apple.mobile.usermanagerd.xpc was invalidated`
- `LaunchServices: store (null) or url (null) was nil: Error Domain=NSOSStatusErrorDomain Code=-54 "process may not map database"`
- `Attempt to map database failed: permission was denied. This attempt will not be retried.`
- `Failed to initialize client context with error ... process may not map database`

**Cause:**  
iOS system services (LaunchServices, User Management) maintain databases that are restricted in sandboxed environments. The app may try to query these services (e.g., for user persona info, app metadata) but lack permissions.

**Impact:** None - the app does not rely on these services for core functionality.

**Action Required:** None, unless you see issues with app launching, file picker permissions, or user account features.

---

### 4. Swift Concurrency Warnings

**Symptoms:**
- `Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.`

**Cause:**  
This warning typically originates from dependencies or system frameworks using legacy synchronization patterns in concurrent contexts. The OpenResponses codebase uses async/await and does not directly call `unsafeForcedSync`.

**Impact:** Potentially performance-related if called from the main thread, but the app's async/await patterns prevent this from being a real issue.

**Action Required:** None, unless you see deadlocks or performance issues. If this warning appears in your code, refactor to use async/await or proper concurrency primitives.

---

### 5. UIDocumentPicker Presentation Errors

**Symptoms:**
- `Attempt to present <UIDocumentPickerViewController: ...> on ... which is already presenting <...>.`

**Cause:**  
SwiftUI's `.fileImporter` and `.sheet` modifiers can try to present multiple pickers/sheets simultaneously if state variables change too quickly (e.g., user taps button multiple times).

**Impact:** User may see a warning, but the picker will still present. Can be jarring if the user taps repeatedly.

**Action Required:** ✅ Fixed - All upload buttons now have guards to prevent double-presentation and are disabled while a picker is active.

---

### 6. Vector Store File Removal Errors

**Symptoms:**
- `Error removing file from vector store: { "error": { "message": "No file found with id 'file-XXX' in vector store 'vs_XXX'." } }`

**Cause:**  
The UI attempted to remove a file that was already deleted or never existed. This can happen if:
- The file was removed via another client/API call
- The UI state became stale (e.g., user left the view open for a long time)
- A concurrent operation removed the file

**Impact:** User sees an error, but it's not a bug - the file is already gone.

**Action Required:** ✅ Fixed - The app now handles "file not found" errors gracefully, refreshes the file list to sync with the backend, and shows a user-friendly message.

---

## When to Investigate

You should **only** investigate these errors if:
1. **User-facing bug:** A feature is broken or the app crashes
2. **Performance issue:** App is slow, unresponsive, or freezes
3. **Data corruption:** Files, vector stores, or chat history are lost/corrupted
4. **Reproducible issue:** The error consistently leads to a problem

## Best Practices

1. **Filter logs:** Use Xcode's console filter to focus on your app's logs (e.g., filter by `[OpenResponses]` or `AppLogger`)
2. **Check AppLogger output:** The app's custom logging categorizes all important events and errors
3. **Use DEBUG mode:** Run in DEBUG mode during development to see verbose logs; disable in production
4. **Test in Simulator and Device:** Some errors only appear in the Simulator due to sandbox restrictions

---

## Summary

Most console errors during iOS app development are benign system-level warnings. The OpenResponses app has been audited to ensure that:
- All critical errors are caught and logged via `AppLogger`
- User-facing issues are handled gracefully with error messages
- State management is robust to prevent stale UI issues

If you encounter a new system error that causes user-facing problems, please update this document with the error details, cause, impact, and solution.

---

**Last Updated:** 2025-10-03  
**Maintained By:** OpenResponses AI Agent
