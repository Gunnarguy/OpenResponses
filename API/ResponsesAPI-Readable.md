# OpenAI Responses API Reference

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Core Endpoints](#core-endpoints)
- [Request Parameters](#request-parameters)
- [Response Format](#response-format)
- [Built-in Tools](#built-in-tools)
- [Streaming](#streaming)
- [Examples](#examples)

---

## Overview

The Responses API (`/v1/responses`) is OpenAI's most advanced interface for generating model responses. It provides:

✅ **Stateful conversations** - Maintains conversation history on the backend  
✅ **Multi-modal inputs** - Supports text, images, files, and audio  
✅ **Built-in tools** - Web search, file search, code interpreter, and more  
✅ **Structured outputs** - JSON schema validation  
✅ **Streaming** - Real-time response generation with detailed events

## Quick Start

### Basic Request

```bash
curl https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "input": "Hello, how can you help me today?"
  }'
```

### Stateful Conversation

```bash
# Use previous_response_id to maintain conversation context
{
  "model": "gpt-4o",
  "input": "What did we just discuss?",
  "previous_response_id": "resp_abc123..."
}
```

---

## Core Endpoints

| Method | Endpoint                         | Description                  |
| ------ | -------------------------------- | ---------------------------- |
| POST   | `/v1/responses`                  | Create a new response        |
| GET    | `/v1/responses/{id}`             | Retrieve a response          |
| DELETE | `/v1/responses/{id}`             | Delete a response            |
| POST   | `/v1/responses/{id}/cancel`      | Cancel a background response |
| GET    | `/v1/responses/{id}/input_items` | List input items             |

---

## Request Parameters

### Essential Parameters

| Parameter              | Type         | Description                     | Default  |
| ---------------------- | ------------ | ------------------------------- | -------- |
| `model`                | string       | Model ID (e.g., "gpt-4o", "o3") | Required |
| `input`                | string/array | Text, image, or file inputs     | Required |
| `previous_response_id` | string       | ID for conversation continuity  | null     |
| `stream`               | boolean      | Enable streaming response       | false    |
| `temperature`          | number       | Sampling temperature (0-2)      | 1.0      |

### Advanced Parameters

<details>
<summary>Click to expand advanced parameters</summary>

| Parameter           | Type          | Description                            |
| ------------------- | ------------- | -------------------------------------- |
| `max_output_tokens` | integer       | Maximum tokens in response             |
| `tools`             | array         | Available tools for the model          |
| `tool_choice`       | string/object | Tool selection strategy                |
| `reasoning`         | object        | Configuration for reasoning models     |
| `text.format`       | object        | Output format (text/json_schema)       |
| `include`           | array         | Additional data to include in response |
| `metadata`          | map           | Custom key-value pairs                 |

</details>

---

## Input Formats

### Text Input

```json
{
  "input": "Simple text input"
}
```

### Structured Input

```json
{
  "input": [
    {
      "role": "system",
      "content": "You are a helpful assistant"
    },
    {
      "role": "user",
      "content": [
        { "type": "input_text", "text": "Analyze this image:" },
        { "type": "input_image", "image_url": "https://..." }
      ]
    }
  ]
}
```

### File Input

```json
{
  "input": [
    {
      "role": "user",
      "content": [
        { "type": "input_text", "text": "Summarize this document:" },
        { "type": "input_file", "file_url": "https://example.com/doc.pdf" }
      ]
    }
  ]
}
```

---

## Built-in Tools

### 🔍 Web Search

```json
{
  "tools": [
    {
      "type": "web_search",
      "search_context_size": "medium",
      "filters": {
        "allowed_domains": ["wikipedia.org", "arxiv.org"]
      }
    }
  ]
}
```

### 📁 File Search

```json
{
  "tools": [
    {
      "type": "file_search",
      "vector_store_ids": ["vs_abc123"],
      "max_num_results": 10
    }
  ]
}
```

### 🐍 Code Interpreter

```json
{
  "tools": [
    {
      "type": "code_interpreter",
      "container": {
        "type": "auto",
        "file_ids": ["file_123"]
      }
    }
  ]
}
```

### 🖼️ Image Generation

```json
{
  "tools": [
    {
      "type": "image_generation",
      "model": "gpt-image-1",
      "size": "1024x1024",
      "quality": "high"
    }
  ]
}
```

---

## Response Format

### Basic Response Structure

```json
{
  "id": "resp_abc123...",
  "object": "response",
  "created_at": 1234567890,
  "status": "completed",
  "model": "gpt-4o",
  "output": [
    {
      "type": "message",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "Here's my response..."
        }
      ]
    }
  ],
  "usage": {
    "input_tokens": 100,
    "output_tokens": 50,
    "total_tokens": 150
  }
}
```

### Tool Call Response

```json
{
  "output": [
    {
      "type": "web_search_call",
      "action": {
        "type": "search",
        "query": "latest AI developments",
        "sources": [{ "type": "url", "url": "https://..." }]
      }
    },
    {
      "type": "message",
      "content": [
        {
          "type": "output_text",
          "text": "Based on my search..."
        }
      ]
    }
  ]
}
```

---

## Streaming

Enable streaming for real-time responses:

```json
{
  "stream": true,
  "stream_options": {
    "include_obfuscation": false
  }
}
```

### Stream Event Types

- `response.started` - Response initiated
- `response.output_item.started` - New output item begins
- `response.output_item.tool_call.started` - Tool call initiated
- `response.output_item.reasoning.started` - Reasoning process begins
- `response.output_item.delta` - Incremental content update
- `response.completed` - Response finished

---

## Structured Outputs

### JSON Schema Validation

```json
{
  "text": {
    "format": {
      "type": "json_schema",
      "name": "product_info",
      "strict": true,
      "schema": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "price": { "type": "number" },
          "in_stock": { "type": "boolean" }
        },
        "required": ["name", "price"]
      }
    }
  }
}
```

---

## Examples

### Multi-turn Conversation

```python
# First turn
response1 = client.responses.create(
    model="gpt-4o",
    input="Tell me about quantum computing"
)

# Second turn - maintains context
response2 = client.responses.create(
    model="gpt-4o",
    input="Can you explain the last point in more detail?",
    previous_response_id=response1.id
)
```

### Web Search + Analysis

```python
response = client.responses.create(
    model="gpt-4o",
    input="What are the latest developments in renewable energy?",
    tools=[{"type": "web_search"}],
    tool_choice="auto"
)
```

### File Analysis with Code

```python
response = client.responses.create(
    model="gpt-4o",
    input=[
        {
            "role": "user",
            "content": [
                {"type": "input_text", "text": "Analyze this CSV and create a chart"},
                {"type": "input_file", "file_id": "file_abc123"}
            ]
        }
    ],
    tools=[{"type": "code_interpreter"}]
)
```

---

## Best Practices

1. **Use `previous_response_id`** for multi-turn conversations instead of manually managing context
2. **Enable streaming** for better UX in real-time applications
3. **Use structured outputs** when you need predictable response formats
4. **Set appropriate `max_output_tokens`** to control response length and costs
5. **Leverage built-in tools** instead of implementing custom solutions
6. **Include relevant metadata** for tracking and debugging

---

## Error Handling

Common error responses:

| Status | Error Code            | Description                  |
| ------ | --------------------- | ---------------------------- |
| 400    | `invalid_request`     | Malformed request parameters |
| 401    | `unauthorized`        | Invalid API key              |
| 429    | `rate_limit_exceeded` | Too many requests            |
| 500    | `internal_error`      | Server error                 |

Example error response:

```json
{
  "error": {
    "code": "invalid_request",
    "message": "Model 'gpt-5' does not exist"
  }
}
```

---

## Additional Resources

- [Text Generation Guide](https://platform.openai.com/docs/guides/text-generation)
- [Function Calling Guide](https://platform.openai.com/docs/guides/function-calling)
- [Structured Outputs Guide](https://platform.openai.com/docs/guides/structured-outputs)
- [Web Search Guide](https://platform.openai.com/docs/guides/web-search)
- [API Rate Limits](https://platform.openai.com/docs/guides/rate-limits)
