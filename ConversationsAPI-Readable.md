# OpenAI Conversations API Reference

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Endpoints](#core-endpoints)
- [Conversation Management](#conversation-management)
- [Item Management](#item-management)
- [Item Types](#item-types)
- [Examples](#examples)

---

## Overview

The Conversations API (`/v1/conversations`) provides **persistent conversation storage** for the Responses API. It allows you to:

✅ **Store conversation state** - Maintain conversation history across API calls  
✅ **Manage conversation items** - Add, retrieve, and delete messages and tool calls  
✅ **Organize with metadata** - Attach custom key-value pairs for organization  
✅ **Paginate through history** - Efficiently retrieve conversation items

> **Key Insight:** This API works in tandem with the Responses API. Use conversation IDs to maintain context across multiple response generations without manually managing message history.

---

## Quick Start

### Create a Conversation

```bash
curl https://api.openai.com/v1/conversations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"topic": "project-planning"},
    "items": [
      {
        "type": "message",
        "role": "user",
        "content": "Let's plan a new feature"
      }
    ]
  }'
```

### Use with Responses API

```bash
# Reference the conversation in a response request
curl https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4o",
    "conversation_id": "conv_123",
    "input": "What should we consider first?"
  }'
```

---

## Core Endpoints

| Method            | Endpoint                                 | Description                  |
| ----------------- | ---------------------------------------- | ---------------------------- |
| **Conversations** |                                          |                              |
| POST              | `/v1/conversations`                      | Create a new conversation    |
| GET               | `/v1/conversations/{id}`                 | Retrieve a conversation      |
| POST              | `/v1/conversations/{id}`                 | Update conversation metadata |
| DELETE            | `/v1/conversations/{id}`                 | Delete a conversation        |
| **Items**         |                                          |                              |
| GET               | `/v1/conversations/{id}/items`           | List conversation items      |
| POST              | `/v1/conversations/{id}/items`           | Add items to conversation    |
| GET               | `/v1/conversations/{id}/items/{item_id}` | Get a specific item          |
| DELETE            | `/v1/conversations/{id}/items/{item_id}` | Delete an item               |

---

## Conversation Management

### Create Conversation

**Request:**

```json
POST /v1/conversations
{
  "metadata": {
    "topic": "customer-support",
    "user_id": "user_456",
    "priority": "high"
  },
  "items": [
    {
      "type": "message",
      "role": "system",
      "content": "You are a helpful support agent"
    }
  ]
}
```

**Response:**

```json
{
  "id": "conv_abc123",
  "object": "conversation",
  "created_at": 1741900000,
  "metadata": {
    "topic": "customer-support",
    "user_id": "user_456",
    "priority": "high"
  }
}
```

### Update Metadata

```json
POST /v1/conversations/{conversation_id}
{
  "metadata": {
    "status": "resolved",
    "resolution_time": "15min"
  }
}
```

**Metadata Limits:**

- Maximum 16 key-value pairs
- Keys: max 64 characters
- Values: max 512 characters

---

## Item Management

### Add Items to Conversation

```json
POST /v1/conversations/{conversation_id}/items
{
  "items": [
    {
      "type": "message",
      "role": "user",
      "content": [
        {"type": "input_text", "text": "Analyze this data"},
        {"type": "input_file", "file_id": "file_xyz"}
      ]
    }
  ]
}
```

**Limits:**

- Add up to 20 items per request
- Items are automatically assigned IDs

### List Items with Pagination

```bash
GET /v1/conversations/{id}/items?limit=10&order=desc&after=msg_123
```

**Query Parameters:**

| Parameter | Type    | Description                 | Default |
| --------- | ------- | --------------------------- | ------- |
| `limit`   | integer | Items per page (1-100)      | 20      |
| `order`   | string  | Sort order: `asc` or `desc` | desc    |
| `after`   | string  | Cursor for pagination       | -       |
| `include` | array   | Additional data to include  | -       |

**Include Options:**

- `web_search_call.action.sources` - Web search sources
- `code_interpreter_call.outputs` - Code execution outputs
- `file_search_call.results` - File search results
- `message.output_text.logprobs` - Token probabilities
- `reasoning.encrypted_content` - Encrypted reasoning

---

## Item Types

### Message Items

Messages are the primary conversation content:

```json
{
  "type": "message",
  "role": "user|assistant|system|developer",
  "content": [
    { "type": "input_text", "text": "Hello" },
    { "type": "input_image", "image_url": "https://..." },
    { "type": "input_file", "file_id": "file_123" },
    {
      "type": "input_audio",
      "input_audio": {
        "data": "base64_audio_data",
        "format": "mp3"
      }
    }
  ]
}
```

**Roles:**

- `system` - High-level instructions
- `developer` - Highest priority instructions
- `user` - User messages
- `assistant` - Model responses

### Tool Call Items

**Web Search:**

```json
{
  "type": "web_search_call",
  "id": "call_123",
  "action": {
    "type": "search",
    "query": "latest AI research"
  },
  "status": "completed"
}
```

**Code Interpreter:**

```json
{
  "type": "code_interpreter_call",
  "id": "call_456",
  "code": "import pandas as pd\ndf = pd.read_csv('data.csv')",
  "container_id": "container_789",
  "outputs": [
    { "type": "logs", "logs": "DataFrame loaded successfully" },
    { "type": "image", "url": "https://...chart.png" }
  ]
}
```

**Function Call:**

```json
{
  "type": "function_call",
  "call_id": "func_789",
  "name": "get_weather",
  "arguments": "{\"location\": \"San Francisco\"}",
  "status": "completed"
}
```

### Tool Output Items

```json
{
  "type": "function_call_output",
  "call_id": "func_789",
  "output": "{\"temperature\": 72, \"conditions\": \"sunny\"}"
}
```

### Reasoning Items

For reasoning models (o1, o3):

```json
{
  "type": "reasoning",
  "id": "reason_123",
  "summary": [
    {
      "type": "summary_text",
      "text": "Breaking down the problem into steps..."
    }
  ],
  "encrypted_content": "encrypted_reasoning_tokens..."
}
```

---

## Complete Examples

### Multi-Turn Conversation with Tools

```python
import requests
import json

# 1. Create conversation with system prompt
response = requests.post(
    "https://api.openai.com/v1/conversations",
    headers={"Authorization": f"Bearer {api_key}"},
    json={
        "metadata": {"project": "data-analysis"},
        "items": [{
            "type": "message",
            "role": "system",
            "content": "You are a data analyst assistant"
        }]
    }
)
conv_id = response.json()["id"]

# 2. Add user message with file
requests.post(
    f"https://api.openai.com/v1/conversations/{conv_id}/items",
    headers={"Authorization": f"Bearer {api_key}"},
    json={
        "items": [{
            "type": "message",
            "role": "user",
            "content": [
                {"type": "input_text", "text": "Analyze this CSV"},
                {"type": "input_file", "file_id": "file_abc123"}
            ]
        }]
    }
)

# 3. Generate response using conversation
response = requests.post(
    "https://api.openai.com/v1/responses",
    headers={"Authorization": f"Bearer {api_key}"},
    json={
        "model": "gpt-4o",
        "conversation_id": conv_id,
        "tools": [{"type": "code_interpreter"}]
    }
)

# 4. List all conversation items
items = requests.get(
    f"https://api.openai.com/v1/conversations/{conv_id}/items",
    headers={"Authorization": f"Bearer {api_key}"},
    params={"include": ["code_interpreter_call.outputs"]}
)
```

### Managing Long Conversations

```python
# Retrieve items in batches
def get_all_items(conv_id, api_key):
    items = []
    has_more = True
    after = None

    while has_more:
        params = {"limit": 100}
        if after:
            params["after"] = after

        response = requests.get(
            f"https://api.openai.com/v1/conversations/{conv_id}/items",
            headers={"Authorization": f"Bearer {api_key}"},
            params=params
        )

        data = response.json()
        items.extend(data["data"])
        has_more = data["has_more"]
        if has_more:
            after = data["last_id"]

    return items
```

### Cleaning Up Old Items

```python
# Delete specific items (e.g., remove PII)
def clean_conversation(conv_id, api_key):
    # Get all items
    response = requests.get(
        f"https://api.openai.com/v1/conversations/{conv_id}/items",
        headers={"Authorization": f"Bearer {api_key}"}
    )

    items = response.json()["data"]

    # Delete items containing sensitive info
    for item in items:
        if should_delete(item):  # Custom logic
            requests.delete(
                f"https://api.openai.com/v1/conversations/{conv_id}/items/{item['id']}",
                headers={"Authorization": f"Bearer {api_key}"}
            )
```

---

## Best Practices

### 1. Use Metadata Effectively

```json
{
  "metadata": {
    "user_id": "usr_123",
    "session_id": "sess_456",
    "topic": "technical-support",
    "language": "en",
    "created_by": "web_app",
    "tags": "urgent,billing"
  }
}
```

### 2. Efficient Item Management

- Add multiple items in a single request (up to 20)
- Use pagination for large conversations
- Include only necessary data with `include` parameter

### 3. Conversation Lifecycle

```python
# Create → Use → Update → Archive/Delete
conv_id = create_conversation()
use_in_responses(conv_id)
update_metadata(conv_id, {"status": "completed"})
archive_or_delete(conv_id)
```

### 4. Error Handling

```python
try:
    response = create_conversation_items(conv_id, items)
except Exception as e:
    if "rate_limit" in str(e):
        time.sleep(1)
        retry()
    elif "not_found" in str(e):
        conv_id = create_new_conversation()
```

---

## Integration with Responses API

The Conversations API is designed to work seamlessly with the Responses API:

### Stateful Responses

```json
POST /v1/responses
{
  "model": "gpt-4o",
  "conversation_id": "conv_123",
  "input": "Continue our discussion"
}
```

The Responses API will:

1. Retrieve conversation history automatically
2. Generate a response with full context
3. Add the response to the conversation
4. Return the response with updated conversation state

### Manual Context Management

If you prefer manual control:

```json
POST /v1/responses
{
  "model": "gpt-4o",
  "store": false,  // Don't auto-store in conversation
  "input": [...],  // Manually provide context
  "previous_response_id": "resp_789"  // Or use response chaining
}
```

---

## Error Codes

| Status | Error                  | Description                      |
| ------ | ---------------------- | -------------------------------- |
| 400    | `invalid_request`      | Malformed request                |
| 404    | `not_found`            | Conversation or item not found   |
| 409    | `conflict`             | Concurrent modification conflict |
| 422    | `unprocessable_entity` | Invalid item structure           |
| 429    | `rate_limit_exceeded`  | Too many requests                |

---

## Additional Resources

- [Responses API Documentation](./ResponsesAPI-Readable.md)
- [OpenAI Platform Docs](https://platform.openai.com/docs)
- [API Rate Limits](https://platform.openai.com/docs/guides/rate-limits)
