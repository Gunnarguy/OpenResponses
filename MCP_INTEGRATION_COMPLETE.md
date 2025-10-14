# MCP (Model Context Protocol) Integration Complete

## Overview
Complete integration of OpenAI's Model Context Protocol (MCP) server support into the OpenResponses iOS app. This allows the app to connect to remote MCP servers (like Notion, Stripe, GitHub, or custom servers) and use their tools during conversations.

## Implementation Summary

### 1. **Settings UI** (`SettingsView.swift`)
Added a complete MCP Server configuration interface:

- **Enable/Disable Toggle**: Turn MCP tool support on/off
- **Server Label**: User-friendly name for the MCP server
- **Server URL**: HTTPS endpoint for the remote MCP server
- **Authorization**: Secure token field (stored in Keychain)
- **Approval Settings**: Control whether tool calls require user approval
- **Allowed Tools**: Comma-separated list of tools to enable
- **Quick Preset Buttons**: One-tap configuration for:
  - Notion (sample deployment from OpenAI docs)
  - Stripe (example custom server)
  - GitHub (example custom server)

**Key Features**:
- Secure credential storage using KeychainService
- Expandable/collapsible configuration section
- Integration with existing Settings UI patterns

### 2. **API Request Building** (`OpenAIService.swift`)
Enhanced the `buildTools` function to construct MCP tool objects:

```swift
if prompt.enableMCPTool, compatibilityService.isToolSupported(APICapabilities.ToolType.mcp, ...) {
    // Load authorization from keychain
    // Parse allowed tools
    // Construct .mcp tool with all parameters
    tools.append(.mcp(
        serverLabel: label,
        serverURL: url,
        authorization: auth,
        requireApproval: approval,
        allowedTools: toolList
    ))
}
```

**Key Features**:
- Automatic authorization loading from Keychain
- Model compatibility checking
- Comma-separated tool parsing
- Full parameter support

### 3. **Streaming Event Models** (`ChatMessage.swift`)
Extended `StreamingEvent` and `StreamingOutputItem` with MCP fields:

**New Fields**:
- `serverLabel`: Identifies which MCP server is being used
- `tools`: Array of available tool names (for list_tools events)
- `name`: MCP tool name being called
- `arguments`: JSON string of tool arguments
- `output`: JSON string of tool response
- `error`: Error message if tool call failed
- `approvalRequestId`: ID for approval workflow

**Supported Event Types**:
- `response.mcp_list_tools.added`
- `response.mcp_call.added`
- `response.mcp_call.done`
- `response.mcp_approval_request.added`

### 4. **Event Handling** (`ChatViewModel+Streaming.swift`)
Implemented comprehensive MCP event handlers:

#### `handleMCPListToolsChunk`
- Logs available tools from the remote server
- Updates activity feed with tool count
- Tracks MCP tool usage for analytics

#### `handleMCPCallAddedChunk`
- Logs when assistant invokes an MCP tool
- Shows tool name and server label
- Updates streaming status to show active tool
- Logs arguments for debugging

#### `handleMCPCallDoneChunk`
- Handles successful completion with output
- Handles failed calls with error messages
- Appends error notifications to chat
- Updates activity feed

#### `handleMCPApprovalRequestChunk`
- Detects approval requests from server
- Appends system message to alert user
- Logs approval request details
- TODO: Full approval UI (similar to computer use)

### 5. **Streaming Status Updates** (`ChatViewModel.swift`)
Added MCP-specific status indicators:

```swift
case "response.mcp_list_tools.added":
    streamingStatus = .runningTool("MCP: \(serverLabel)")
    logActivity("🔧 MCP: Listing tools from \(serverLabel)")

case "response.mcp_call.added":
    streamingStatus = .runningTool("MCP: \(toolName)")
    logActivity("🔧 MCP: Calling \(toolName) on \(serverLabel)")

case "response.mcp_call.done":
    logActivity("✅ MCP: \(toolName) completed")

case "response.mcp_approval_request.added":
    streamingStatus = .runningTool("MCP: Awaiting approval")
    logActivity("🔒 MCP: \(toolName) requires approval")
```

**Key Features**:
- User-friendly status chips in UI
- Activity feed integration
- Server and tool name display
- Approval workflow indication

## Data Flow

1. **Configuration** (User → Settings UI → Prompt → Keychain)
   - User enters MCP server details in Settings
   - Authorization saved securely to Keychain
   - Configuration stored in Prompt model

2. **Request Building** (ChatViewModel → OpenAIService → API)
   - User sends a message
   - OpenAIService checks if MCP tool is enabled
   - Loads authorization from Keychain
   - Constructs MCP tool in request payload
   - Sends to OpenAI Responses API

3. **Streaming Events** (API → OpenAIService → ChatViewModel)
   - OpenAI connects to remote MCP server
   - Server lists available tools → `mcp_list_tools.added`
   - Assistant calls a tool → `mcp_call.added`
   - Tool execution completes → `mcp_call.done`
   - Approval needed → `mcp_approval_request.added`

4. **UI Updates** (ChatViewModel → SwiftUI Views)
   - Status chip shows "MCP: tool_name"
   - Activity feed shows progress
   - System messages for errors/approvals
   - Tool usage tracked in message metadata

## Security Features

1. **Secure Storage**
   - Authorization tokens stored in iOS Keychain
   - Key format: `mcp_auth_{serverLabel}`
   - Never stored in UserDefaults or plain files

2. **User Control**
   - Explicit enable/disable toggle
   - Server URL visibility
   - Approval settings per server
   - Tool filtering via allowedTools

3. **Logging & Debugging**
   - All MCP events logged with AppLogger
   - Tool arguments logged at debug level
   - Error details captured and surfaced
   - Server labels visible in all logs

## Testing Recommendations

1. **Basic Flow**
   - Enable MCP tool in Settings
   - Configure Notion server (sample deployment)
   - Send message requesting Notion data
   - Verify tool listing and execution

2. **Error Handling**
   - Test with invalid server URL
   - Test with missing authorization
   - Test network failure scenarios
   - Verify error messages in chat

3. **Approval Flow**
   - Configure server with `require_approval: true`
   - Trigger tool call requiring approval
   - Verify system message appears
   - (Future) Test approval UI

4. **Tool Filtering**
   - Set `allowedTools` to specific list
   - Verify only those tools are available
   - Test with empty list (all tools allowed)

## Future Enhancements

1. **Approval UI**
   - Implement sheet similar to computer use safety approval
   - Show tool name, arguments, server label
   - Approve/Deny buttons
   - Continue conversation after approval

2. **Multi-Server Support**
   - Support multiple MCP servers simultaneously
   - Array of server configurations
   - Server selection UI
   - Per-conversation server preferences

3. **OAuth Integration**
   - Support OAuth 2.0 flow for connectors
   - Handle token refresh
   - Secure token exchange

4. **Tool Discovery UI**
   - Display available tools from server
   - Tool descriptions and schemas
   - Interactive tool tester

## Files Modified

1. `OpenResponses/Features/Onboarding/Views/SettingsView.swift`
   - Added MCP configuration UI
   - Lines 780-810, 1023-1190

2. `OpenResponses/Core/Services/OpenAIService.swift`
   - Added MCP tool construction in `buildTools`
   - Lines 713-850

3. `OpenResponses/Shared/Models/ChatMessage.swift`
   - Extended StreamingEvent with MCP fields
   - Extended StreamingOutputItem with MCP fields
   - Lines 339-691

4. `OpenResponses/Features/Chat/ViewModels/ChatViewModel+Streaming.swift`
   - Added MCP event handlers
   - Lines 44-54 (switch cases)
   - Lines 350-440 (handler implementations)

5. `OpenResponses/Features/Chat/ViewModels/ChatViewModel.swift`
   - Added MCP status indicators
   - Lines 2335-2365 (status updates)

## Documentation References

- **OpenAI MCP Documentation**: `docs/Documentation/connectors.md`
- **API Reference**: Responses API with MCP tool support
- **MCP Protocol**: https://modelcontextprotocol.io/introduction

## Compliance with Project Guidelines

✅ **MVVM Architecture**: Event handling in ViewModel, UI in SwiftUI Views
✅ **Secure Storage**: KeychainService for sensitive credentials
✅ **Error Handling**: Comprehensive logging and user-facing error messages
✅ **User Control**: Explicit enable/disable and configuration options
✅ **Activity Feedback**: Status chips and activity feed integration
✅ **Analytics**: Tool usage tracking via existing analytics service
✅ **Code Comments**: Detailed documentation for all new functions

## Status

**✅ Complete - Ready for Testing**

The MCP integration is fully implemented and follows all existing patterns in the codebase. The approval UI is the only remaining enhancement, marked as TODO with clear guidance for future implementation.
