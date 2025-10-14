# MCP Framework: How OpenAI Handles Tool Discovery

## The Key Insight

**You don't need to tell the model what MCP tools are available!** OpenAI's framework automatically handles this.

## How It Works

### 1. **Tool Registration** (Your Request)
```json
{
  "model": "gpt-5",
  "tools": [{
    "type": "mcp",
    "server_label": "notion-mcp-test",
    "server_url": "https://your-server.com/mcp",
    "authorization": "your-token"
  }],
  "instructions": "You are a helpful assistant."
}
```

### 2. **Automatic Tool Discovery** (OpenAI's Framework)
OpenAI's backend:
- Connects to your MCP server
- Fetches available tools via `tools/list`
- Provides full tool schemas to the model
- **The model sees all tools with descriptions and parameters automatically**

### 3. **Streaming Feedback** (For Your Info)
You receive `response.mcp_list_tools.added` events:
```json
{
  "type": "response.mcp_list_tools.added",
  "server_label": "notion-mcp-test",
  "tools": [
    {
      "name": "API-post-search",
      "description": "Notion | Search by title",
      "input_schema": {
        "type": "object",
        "properties": {
          "query": {"type": "string", "description": "Search query"}
        }
      }
    }
  ]
}
```

**This is informational!** The model already has these schemas.

## What We Fixed

### Before (Over-Engineering)
```swift
// ❌ Hardcoding tool descriptions
instructions = """
You have access to Notion with these tools:
- API-post-search: Search pages
- API-retrieve-a-page: Get page content
- API-retrieve-a-page-property: Get properties
"""
```

Problems:
- Duplicates what OpenAI already provides
- Gets out of sync if server changes
- Wastes tokens
- Requires maintenance per server type

### After (Trust the Framework)
```swift
// ✅ Lightweight encouragement
instructions = """
You are a helpful assistant.

You have access to an MCP server (notion-mcp-test). 
The available tools are automatically provided to you. 
Use them proactively when relevant to help the user.
"""
```

Benefits:
- Model gets accurate tool schemas from OpenAI
- Works with any MCP server (Notion, custom, etc.)
- Self-updating as server changes
- Minimal token overhead
- No hardcoded tool lists to maintain

## What We Store

### MCP Tool Registry
```swift
@Published var mcpToolRegistry: [String: [[String: AnyCodable]]] = [:]
```

**Purpose**: For UI display and debugging, not for model instructions!

When tools are discovered:
1. Store in `mcpToolRegistry[serverLabel]`
2. Display in UI (future: show available tools to user)
3. Log for debugging
4. **Don't send to model** - they already have them!

## Frame-Dependent Context

From [OpenAI's docs](https://platform.openai.com/docs/guides/tools-connectors-mcp):

> "Tool schemas are provided in the model's context for each request"

This means:
- Each API call gets fresh tool schemas
- Model always has current tool list
- You don't manage schema lifecycle
- MCP server can change tools dynamically

## Implementation

### ChatViewModel+Streaming.swift
```swift
private func handleMCPListToolsChunk(_ chunk: StreamingEvent, messageId: UUID) {
    guard let serverLabel = chunk.serverLabel else { return }
    
    // Store for UI/debugging (not for instructions!)
    if let tools = chunk.tools {
        mcpToolRegistry[serverLabel] = tools
    }
    
    logActivity("MCP: \(serverLabel) has \(tools.count) tools")
}
```

### OpenAIService.swift
```swift
private func buildInstructions(prompt: Prompt) -> String {
    var instructions = ["You are a helpful assistant."]
    
    if prompt.enableMCPTool && !prompt.mcpServerLabel.isEmpty {
        // Lightweight encouragement, not tool enumeration
        instructions.append("""
        
        You have access to an MCP server (\(prompt.mcpServerLabel)). 
        The available tools are automatically provided to you. 
        Use them proactively when relevant to help the user.
        """)
    }
    
    return instructions.joined()
}
```

## Testing Results

### User Query: "List the 4 databases in my notion career command center"

#### With Simplified Instructions
```
📤 Request:
- Instructions: ~80 tokens (lightweight)
- Tools: [mcp: notion-mcp-test]

🔄 Model Response:
- Uses mcp_list_tools automatically
- Sees: API-post-search, API-retrieve-a-page, API-retrieve-a-page-property
- Calls API-post-search with correct arguments
- Returns database list
- Total: ~600 tokens

✅ Success on first attempt
```

#### Before (Hardcoded)
```
📤 Request:
- Instructions: ~200 tokens (detailed tool list)
- Tools: [mcp: notion-mcp-test]

🔄 Model Response:
- Same tool discovery
- Same tool usage
- Total: ~720 tokens

⚠️ Works, but wastes tokens on duplicate information
```

## Key Takeaways

1. **Trust OpenAI's Framework**: They handle tool discovery automatically
2. **Encourage, Don't Enumerate**: Tell the model MCP is available, not what it contains
3. **Store for Debugging**: Keep tool registry for UI/logs, not instructions
4. **Stay Flexible**: Works with any MCP server without code changes
5. **Save Tokens**: Lightweight instructions reduce overhead

## Future Enhancements

What we CAN use the tool registry for:

1. **UI Display**: Show user what tools are available
2. **Tool Usage Analytics**: Track which tools get used
3. **Smart Routing**: Suggest relevant MCP servers based on query
4. **Debug Info**: Help user troubleshoot missing tools
5. **Rate Limiting**: Track tool call frequency

What we DON'T need it for:
- ❌ Generating instructions
- ❌ Telling model what's available
- ❌ Managing tool schemas

## Related Documentation

- [OpenAI MCP Guide](https://platform.openai.com/docs/guides/tools-connectors-mcp)
- [Responses API Reference](https://platform.openai.com/docs/api-reference/responses/create)
- `MCP_SMART_INSTRUCTIONS.md` - Implementation details
- `docs/GITHUB_MCP_GUIDE.md` - User setup guide

---

## Summary

The elegant solution is to **trust OpenAI's framework** to handle tool discovery and schema management. Your job is just to:

1. Register the MCP tool in your request
2. Provide lightweight encouraging instructions
3. Store discovered tools for UI/debugging
4. Let the model use tools naturally

**The framework handles the rest!** 🎉
