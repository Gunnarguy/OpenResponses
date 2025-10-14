# MCP Server Label Validation Fix

## Problem

The OpenAI Responses API was rejecting MCP server configurations with a **400 error**:

```json
{
  "error": {
    "message": "Invalid input Notion MCP (Official): 'server_label' must start with a letter and consist of only letters, digits, '-' and '_'",
    "type": "invalid_request_error",
    "param": "tools"
  }
}
```

**Root Cause:** The Notion MCP template had a label containing **spaces and parentheses**: `"Notion MCP (Official)"`

## API Requirements

According to the OpenAI API, `server_label` must:
- ✅ Start with a letter
- ✅ Contain only: letters, digits, `-`, `_`
- ❌ NO spaces
- ❌ NO parentheses or special characters

## Solution

### 1. Added `displayLabel` Property

Updated `RemoteMCPServer` struct to separate API label from UI display:

```swift
struct RemoteMCPServer: Identifiable, Codable, Hashable {
    var label: String           // API-compliant: "notion-mcp-official"
    var displayLabel: String?   // User-friendly: "Notion MCP (Official)"
    
    var uiLabel: String {
        displayLabel ?? label   // Show displayLabel in UI, fall back to label
    }
}
```

### 2. Fixed Template Label

**Before:**
```swift
label: "Notion MCP (Official)"  // ❌ Contains spaces and ()
```

**After:**
```swift
label: "notion-mcp-official",           // ✅ API-compliant
displayLabel: "Notion MCP (Official)"   // ✅ User-friendly UI
```

### 3. Updated UI to Use `uiLabel`

In `SettingsView.swift`:
```swift
Text(template.uiLabel)  // Shows "Notion MCP (Official)" in UI
```

While the API receives:
```json
{
  "server_label": "notion-mcp-official"  // Valid!
}
```

## Files Changed

1. **`MCPConnector.swift`**
   - Added `displayLabel` property to `RemoteMCPServer`
   - Added `uiLabel` computed property
   - Updated `notionOfficial` template with compliant label
   - Updated init to include `displayLabel` parameter

2. **`SettingsView.swift`**
   - Changed `Text(template.label)` → `Text(template.uiLabel)`
   - Maintains user-friendly display while API gets valid labels

## Validation

The Notion-specific instructions still work because they check:
```swift
if prompt.mcpServerLabel.lowercased().contains("notion") {
    // "notion-mcp-official".contains("notion") ✅
}
```

## Result

- ✅ **API accepts the label** (`notion-mcp-official`)
- ✅ **UI shows friendly name** ("Notion MCP (Official)")
- ✅ **Instructions still trigger** (contains "notion")
- ✅ **Template picker works** with proper label validation
- ✅ **Custom servers unaffected** (users can still manually configure)

## Testing Recommendation

1. Restart app to load updated template
2. Go to Settings → MCP Configuration
3. Click "Notion MCP (Official)" template
4. Verify label field shows: `notion-mcp-official`
5. Send test message with Notion query
6. Check logs for `"server_label": "notion-mcp-official"` (no 400 error)

## Backwards Compatibility

Existing custom servers with invalid labels will:
- Still work for now (stored in UserDefaults)
- Get validation errors if OpenAI enforces strictly
- Can be updated by re-selecting from template or manual edit

## Future Templates

When adding new MCP templates, ensure labels follow pattern:
```
✅ "server-name-description"
✅ "notion-mcp-official"
✅ "google-drive-connector"
❌ "Server Name (Description)"
❌ "My Custom Server!"
```
