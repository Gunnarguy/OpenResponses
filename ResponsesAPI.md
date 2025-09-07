# Responses API Reference

OpenAI's most advanced interface for generating model responses. Supports text and image inputs, and text outputs. Create stateful interactions with the model, using the output of previous responses as input. Extend the model's capabilities with built-in tools for file search, web search, computer use, and more. Allow the model access to external systems and data using function calling.

## Related Guides

- [Quickstart](https://platform.openai.com/docs/quickstart)
- [Text inputs and outputs](https://platform.openai.com/docs/guides/text)
- [Image inputs](https://platform.openai.com/docs/guides/images)
- [Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs)
- [Function calling](https://platform.openai.com/docs/guides/function-calling)
- [Conversation state](https://platform.openai.com/docs/guides/conversation-state)
- [Extend the models with tools](https://platform.openai.com/docs/guides/tools)

## Endpoints

### Create a Model Response

`POST https://api.openai.com/v1/responses`

Creates a model response. Provide text or image inputs to generate text or JSON outputs. Have the model call your own custom code or use built-in tools like web search or file search to use your own data as input for the model's response.

#### Request Body

| Parameter              | Type                 | Required | Default        | Description                                                                                                                          |
| ---------------------- | -------------------- | -------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `background`           | `boolean` or `null`  | Optional | `false`        | Whether to run the model response in the background. [Learn more](https://platform.openai.com/docs/guides/background).               |
| `conversation`         | `string` or `object` | Optional | `null`         | The conversation that this response belongs to. Items from this conversation are prepended to input_items for this response request. |
| `include`              | `array` or `null`    | Optional | -              | Specify additional output data to include in the model response.                                                                     |
| `input`                | `string` or `array`  | Optional | -              | Text, image, or file inputs to the model, used to generate a response.                                                               |
| `instructions`         | `string` or `null`   | Optional | -              | A system (or developer) message inserted into the model's context.                                                                   |
| `max_output_tokens`    | `integer` or `null`  | Optional | -              | An upper bound for the number of tokens that can be generated for a response.                                                        |
| `max_tool_calls`       | `integer` or `null`  | Optional | -              | The maximum number of total calls to built-in tools that can be processed in a response.                                             |
| `metadata`             | `map`                | Optional | -              | Set of 16 key-value pairs that can be attached to an object.                                                                         |
| `model`                | `string`             | Optional | -              | Model ID used to generate the response, like `gpt-4o` or `o3`.                                                                       |
| `parallel_tool_calls`  | `boolean` or `null`  | Optional | `true`         | Whether to allow the model to run tool calls in parallel.                                                                            |
| `previous_response_id` | `string` or `null`   | Optional | -              | The unique ID of the previous response to the model. Use this to create multi-turn conversations.                                    |
| `prompt`               | `object` or `null`   | Optional | -              | Reference to a prompt template and its variables.                                                                                    |
| `prompt_cache_key`     | `string`             | Optional | -              | Used by OpenAI to cache responses for similar requests to optimize your cache hit rates.                                             |
| `reasoning`            | `object` or `null`   | Optional | -              | Configuration options for reasoning models (gpt-5 and o-series models only).                                                         |
| `safety_identifier`    | `string`             | Optional | -              | A stable identifier used to help detect users that may be violating OpenAI's usage policies.                                         |
| `service_tier`         | `string` or `null`   | Optional | `auto`         | Specifies the processing type used for serving the request.                                                                          |
| `store`                | `boolean` or `null`  | Optional | `true`         | Whether to store the generated model response for later retrieval via API.                                                           |
| `stream`               | `boolean` or `null`  | Optional | `false`        | If set to true, the model response data will be streamed to the client using server-sent events.                                     |
| `stream_options`       | `object` or `null`   | Optional | `null`         | Options for streaming responses. Only set this when you set `stream: true`.                                                          |
| `temperature`          | `number` or `null`   | Optional | `1`            | What sampling temperature to use, between 0 and 2.                                                                                   |
| `text`                 | `object`             | Optional | -              | Configuration options for a text response from the model.                                                                            |
| `tool_choice`          | `string` or `object` | Optional | -              | How the model should select which tool (or tools) to use when generating a response.                                                 |
| `tools`                | `array`              | Optional | -              | An array of tools the model may call while generating a response.                                                                    |
| `top_logprobs`         | `integer` or `null`  | Optional | -              | An integer between 0 and 20 specifying the number of most likely tokens to return at each token position.                            |
| `top_p`                | `number` or `null`   | Optional | `1`            | An alternative to sampling with temperature, called nucleus sampling.                                                                |
| `truncation`           | `string` or `null`   | Optional | `disabled`     | The truncation strategy to use for the model response.                                                                               |
| `user`                 | `string`             | Optional | **Deprecated** | This field is being replaced by `safety_identifier` and `prompt_cache_key`.                                                          |
| `verbosity`            | `string` or `null`   | Optional | `medium`       | Constrains the verbosity of the model's response.                                                                                    |

#### Include Parameter Values

The `include` parameter supports the following values:

- `web_search_call.action.sources` - Include the sources of the web search tool call
- `code_interpreter_call.outputs` - Includes the outputs of python code execution
- `computer_call_output.output.image_url` - Include image URLs from the computer call output
- `file_search_call.results` - Include the search results of the file search tool call
- `message.input_image.image_url` - Include image URLs from the input message
- `message.output_text.logprobs` - Include logprobs with assistant messages
- `reasoning.encrypted_content` - Includes an encrypted version of reasoning tokens

#### Conversation Parameter

The conversation parameter can be either:

##### Conversation ID (string)

The unique ID of the conversation.

##### Conversation Object

```json
{
  "id": "string" // Required - The unique ID of the conversation
}
```

#### Input Types

The `input` parameter accepts various formats:

##### Text Input (string)

A simple text input to the model, equivalent to a text input with the user role.

##### Input Item List (array)

A list of one or many input items to the model, containing different content types.

###### Input Message Object

```json
{
  "type": "message", // Optional
  "role": "user", // Required - One of: user, assistant, system, developer
  "content": "string or array" // Required - Text, image, or audio input
}
```

###### Content Types

**Input Text**

```json
{
  "type": "input_text",
  "text": "string"
}
```

**Input Image**

```json
{
  "type": "input_image",
  "detail": "high", // One of: high, low, auto (default: auto)
  "file_id": "string", // Optional
  "image_url": "string" // Optional - URL or base64 encoded image
}
```

**Input File**

```json
{
  "type": "input_file",
  "file_data": "string", // Optional
  "file_id": "string", // Optional
  "file_url": "string", // Optional
  "filename": "string" // Optional
}
```

**Input Audio**

```json
{
  "type": "input_audio",
  "input_audio": {
    "data": "string", // Base64-encoded audio data
    "format": "mp3" // One of: mp3, wav
  }
}
```

#### Reasoning Configuration

For gpt-5 and o-series models only:

```json
{
  "effort": "medium", // Optional - One of: minimal, low, medium, high
  "summary": "auto" // Optional - One of: auto, concise, detailed
}
```

#### Text Format Configuration

```json
{
  "format": {
    "type": "text" // or "json_schema" or "json_object"
  }
}
```

For JSON Schema (Structured Outputs):

```json
{
  "format": {
    "type": "json_schema",
    "name": "response_format_name",
    "schema": {}, // JSON Schema object
    "description": "string", // Optional
    "strict": true // Optional - defaults to false
  }
}
```

#### Tool Choice Options

The `tool_choice` parameter controls how the model selects tools:

- `"none"` - The model will not call any tool and instead generates a message
- `"auto"` - The model can pick between generating a message or calling one or more tools
- `"required"` - The model must call one or more tools

##### Allowed Tools Object

```json
{
  "type": "allowed_tools",
  "mode": "auto", // or "required"
  "tools": [
    // Array of tool definitions
  ]
}
```

##### Specific Tool Selection

```json
{
  "type": "function",
  "name": "function_name"
}
```

#### Tools Array

The `tools` parameter accepts various tool types:

##### Function Tool

```json
{
  "type": "function",
  "name": "get_weather",
  "description": "Get the current weather", // Optional
  "parameters": {}, // JSON Schema object
  "strict": true // Required - Whether to enforce strict parameter validation
}
```

##### File Search Tool

```json
{
  "type": "file_search",
  "vector_store_ids": ["vs_123", "vs_456"],
  "filters": {}, // Optional - Comparison or Compound filter
  "max_num_results": 10, // Optional - Between 1 and 50
  "ranking_options": {
    // Optional
    "ranker": "string",
    "score_threshold": 0.5 // Number between 0 and 1
  }
}
```

##### Web Search Tool

```json
{
  "type": "web_search", // or "web_search_2025_08_26"
  "search_context_size": "medium", // Optional - One of: low, medium, high
  "filters": {
    "allowed_domains": ["example.com"] // Optional
  },
  "user_location": {
    // Optional
    "type": "approximate",
    "city": "San Francisco",
    "country": "US",
    "region": "California",
    "timezone": "America/Los_Angeles"
  }
}
```

##### Computer Use Tool (Preview)

```json
{
  "type": "computer_use_preview",
  "environment": "string",
  "display_width": 1920,
  "display_height": 1080
}
```

##### Code Interpreter Tool

```json
{
  "type": "code_interpreter",
  "container": "container_id" // or object with file_ids
}
```

##### Image Generation Tool

```json
{
  "type": "image_generation",
  "model": "gpt-image-1", // Optional - defaults to gpt-image-1
  "size": "auto", // Optional - One of: 1024x1024, 1024x1536, 1536x1024, auto
  "quality": "auto", // Optional - One of: low, medium, high, auto
  "output_format": "png", // Optional - One of: png, webp, jpeg
  "background": "auto", // Optional - One of: transparent, opaque, auto
  "partial_images": 0 // Optional - 0 to 3 for streaming mode
}
```

##### MCP Tool

```json
{
  "type": "mcp",
  "server_label": "my_server",
  "server_url": "https://example.com/mcp", // or use connector_id
  "connector_id": "connector_googledrive", // Alternative to server_url
  "allowed_tools": ["tool1", "tool2"], // Optional
  "authorization": "Bearer token", // Optional
  "headers": {}, // Optional
  "require_approval": "always", // Optional - always, never, or filter object
  "server_description": "string" // Optional
}
```

Supported connector IDs:

- `connector_dropbox`
- `connector_gmail`
- `connector_googlecalendar`
- `connector_googledrive`
- `connector_microsoftteams`
- `connector_outlookcalendar`
- `connector_outlookemail`
- `connector_sharepoint`

##### Custom Tool

```json
{
  "type": "custom",
  "name": "my_custom_tool",
  "description": "string", // Optional
  "format": {
    "type": "text" // or "grammar" with definition and syntax
  }
}
```

##### Local Shell Tool

```json
{
  "type": "local_shell"
}
```

#### Example Request

```bash
curl https://api.openai.com/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4o",
    "input": "Hello, how are you?",
    "stream": false,
    "tools": [
      {
        "type": "web_search",
        "search_context_size": "medium"
      }
    ]
  }'
```

#### Response

Returns a [Response object](#the-response-object).

### Get a Model Response

`GET https://api.openai.com/v1/responses/{response_id}`

Retrieves a model response with the given ID.

#### Path Parameters

| Parameter     | Type     | Required | Description                        |
| ------------- | -------- | -------- | ---------------------------------- |
| `response_id` | `string` | Required | The ID of the response to retrieve |

#### Query Parameters

| Parameter             | Type      | Required | Description                                                     |
| --------------------- | --------- | -------- | --------------------------------------------------------------- |
| `include`             | `array`   | Optional | Additional fields to include in the response                    |
| `include_obfuscation` | `boolean` | Optional | When true, stream obfuscation will be enabled                   |
| `starting_after`      | `integer` | Optional | The sequence number of the event after which to start streaming |
| `stream`              | `boolean` | Optional | If set to true, the model response data will be streamed        |

#### Example Request

```bash
curl https://api.openai.com/v1/responses/resp_123 \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Delete a Model Response

`DELETE https://api.openai.com/v1/responses/{response_id}`

Deletes a model response with the given ID.

#### Path Parameters

| Parameter     | Type     | Required | Description                      |
| ------------- | -------- | -------- | -------------------------------- |
| `response_id` | `string` | Required | The ID of the response to delete |

#### Example Request

```bash
curl -X DELETE https://api.openai.com/v1/responses/resp_123 \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Cancel a Response

`POST https://api.openai.com/v1/responses/{response_id}/cancel`

Cancels a model response with the given ID. Only responses created with the `background` parameter set to `true` can be cancelled.

#### Path Parameters

| Parameter     | Type     | Required | Description                      |
| ------------- | -------- | -------- | -------------------------------- |
| `response_id` | `string` | Required | The ID of the response to cancel |

#### Example Request

```bash
curl -X POST https://api.openai.com/v1/responses/resp_123/cancel \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### List Input Items

`GET https://api.openai.com/v1/responses/{response_id}/input_items`

Returns a list of input items for a given response.

#### Path Parameters

| Parameter     | Type     | Required | Description                                        |
| ------------- | -------- | -------- | -------------------------------------------------- |
| `response_id` | `string` | Required | The ID of the response to retrieve input items for |

#### Query Parameters

| Parameter | Type      | Required | Default | Description                                              |
| --------- | --------- | -------- | ------- | -------------------------------------------------------- |
| `after`   | `string`  | Optional | -       | An item ID to list items after, used in pagination       |
| `include` | `array`   | Optional | -       | Additional fields to include in the response             |
| `limit`   | `integer` | Optional | `20`    | A limit on the number of objects to be returned (1-100)  |
| `order`   | `string`  | Optional | `desc`  | The order to return the input items in (`asc` or `desc`) |

#### Example Request

```bash
curl https://api.openai.com/v1/responses/resp_abc123/input_items \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

## The Response Object

The response object contains information about the AI model's response.

### Properties

| Property               | Type                 | Description                                                                       |
| ---------------------- | -------------------- | --------------------------------------------------------------------------------- |
| `id`                   | `string`             | Unique identifier for this Response                                               |
| `object`               | `string`             | Always `"response"`                                                               |
| `created_at`           | `number`             | Unix timestamp (in seconds) of when this Response was created                     |
| `status`               | `string`             | One of: `completed`, `failed`, `in_progress`, `cancelled`, `queued`, `incomplete` |
| `error`                | `object` or `null`   | An error object returned when the model fails to generate a Response              |
| `incomplete_details`   | `object` or `null`   | Details about why the response is incomplete                                      |
| `instructions`         | `string` or `array`  | A system (or developer) message inserted into the model's context                 |
| `model`                | `string`             | Model ID used to generate the response                                            |
| `output`               | `array`              | An array of content items generated by the model                                  |
| `output_text`          | `string` or `null`   | **SDK-only** convenience property containing aggregated text output               |
| `metadata`             | `map`                | Set of 16 key-value pairs for storing additional information                      |
| `usage`                | `object` or `null`   | Token usage details                                                               |
| `background`           | `boolean` or `null`  | Whether the response runs in the background                                       |
| `conversation`         | `object` or `null`   | The conversation this response belongs to                                         |
| `max_output_tokens`    | `integer` or `null`  | Upper bound for tokens that can be generated                                      |
| `max_tool_calls`       | `integer` or `null`  | Maximum number of total calls to built-in tools                                   |
| `parallel_tool_calls`  | `boolean`            | Whether to allow parallel tool calls                                              |
| `previous_response_id` | `string` or `null`   | ID of the previous response for multi-turn conversations                          |
| `prompt`               | `object` or `null`   | Reference to a prompt template and its variables                                  |
| `prompt_cache_key`     | `string`             | Used by OpenAI to cache responses                                                 |
| `reasoning`            | `object` or `null`   | Configuration options for reasoning models                                        |
| `safety_identifier`    | `string`             | Stable identifier for detecting policy violations                                 |
| `service_tier`         | `string` or `null`   | Processing type used for serving the request                                      |
| `temperature`          | `number` or `null`   | Sampling temperature used                                                         |
| `text`                 | `object`             | Configuration options for text response                                           |
| `tool_choice`          | `string` or `object` | How the model selects tools                                                       |
| `tools`                | `array`              | Array of tools the model may call                                                 |
| `top_logprobs`         | `integer` or `null`  | Number of most likely tokens to return                                            |
| `top_p`                | `number` or `null`   | Nucleus sampling parameter                                                        |
| `truncation`           | `string` or `null`   | Truncation strategy used                                                          |
| `verbosity`            | `string` or `null`   | Verbosity constraint for the response                                             |

### Error Object

When a response fails, the error object contains:

```json
{
  "code": "string",
  "message": "string"
}
```

### Incomplete Details Object

When a response is incomplete:

```json
{
  "reason": "string"
}
```

### Usage Object

Token usage information:

```json
{
  "input_tokens": 100,
  "output_tokens": 50,
  "total_tokens": 150,
  "input_tokens_details": {
    "cached_tokens": 20
  },
  "output_tokens_details": {
    "reasoning_tokens": 10
  }
}
```

## Output Types

The `output` array can contain various types of items:

### Output Message

The most common output type containing the assistant's response:

```json
{
  "id": "msg_123",
  "type": "message",
  "role": "assistant",
  "status": "completed", // One of: in_progress, completed, incomplete
  "content": [
    {
      "type": "output_text",
      "text": "Hello! I'm doing well, thank you for asking.",
      "annotations": [],
      "logprobs": [] // Optional
    }
  ]
}
```

### Content Part Types

#### Output Text

```json
{
  "type": "output_text",
  "text": "string",
  "annotations": [], // Array of annotation objects
  "logprobs": [] // Optional array of LogProb objects
}
```

#### Refusal

```json
{
  "type": "refusal",
  "refusal": "I cannot help with that request."
}
```

### Annotation Types

Annotations provide additional context and citations:

#### File Citation

```json
{
  "type": "file_citation",
  "file_id": "file_123",
  "filename": "document.pdf",
  "index": 0
}
```

#### URL Citation

```json
{
  "type": "url_citation",
  "url": "https://example.com",
  "title": "Example Page",
  "start_index": 10,
  "end_index": 25
}
```

#### Container File Citation

```json
{
  "type": "container_file_citation",
  "container_id": "container_123",
  "file_id": "file_456",
  "filename": "data.json",
  "start_index": 5,
  "end_index": 15
}
```

#### File Path

```json
{
  "type": "file_path",
  "file_id": "file_789",
  "index": 0
}
```

## Tool Call Output Types

### File Search Tool Call

```json
{
  "id": "call_123",
  "type": "file_search_call",
  "status": "completed", // One of: in_progress, searching, incomplete, failed
  "queries": ["search query"],
  "results": [
    {
      "file_id": "file_123",
      "filename": "document.pdf",
      "score": 0.95,
      "text": "Relevant content...",
      "attributes": {}
    }
  ]
}
```

### Web Search Tool Call

```json
{
  "id": "call_456",
  "type": "web_search_call",
  "status": "completed",
  "action": {
    "type": "search",
    "query": "OpenAI GPT-4",
    "sources": [
      {
        "type": "url",
        "url": "https://example.com"
      }
    ]
  }
}
```

### Function Tool Call

```json
{
  "id": "call_789",
  "type": "function_call",
  "call_id": "func_123",
  "name": "get_weather",
  "arguments": "{\"location\": \"San Francisco\"}",
  "status": "completed"
}
```

### Computer Tool Call

```json
{
  "id": "call_computer",
  "type": "computer_call",
  "call_id": "comp_123",
  "status": "completed",
  "action": {
    "type": "screenshot"
  },
  "pending_safety_checks": []
}
```

Computer actions include:

- `click` - Mouse click at coordinates
- `double_click` - Double click at coordinates
- `drag` - Drag along a path
- `keypress` - Press key combinations
- `move` - Move mouse to coordinates
- `screenshot` - Take a screenshot
- `scroll` - Scroll at coordinates
- `type` - Type text
- `wait` - Wait for a period

### Code Interpreter Tool Call

```json
{
  "id": "call_code",
  "type": "code_interpreter_call",
  "status": "completed", // One of: in_progress, completed, incomplete, interpreting, failed
  "container_id": "container_123",
  "code": "import math\nprint(math.pi)",
  "outputs": [
    {
      "type": "logs",
      "logs": "3.141592653589793"
    }
  ]
}
```

### Image Generation Call

```json
{
  "id": "call_image",
  "type": "image_generation_call",
  "status": "completed",
  "result": "base64_encoded_image_data..."
}
```

### Reasoning Output

For models with reasoning capabilities:

```json
{
  "id": "reasoning_123",
  "type": "reasoning",
  "status": "completed",
  "summary": [
    {
      "type": "summary_text",
      "text": "The model considered..."
    }
  ],
  "content": [
    {
      "type": "reasoning_text",
      "text": "Step by step reasoning..."
    }
  ],
  "encrypted_content": null
}
```

### MCP Tool Call

```json
{
  "id": "call_mcp",
  "type": "mcp_call",
  "server_label": "my_server",
  "name": "tool_name",
  "arguments": "{}",
  "output": "result",
  "error": null
}
```

### Custom Tool Call

```json
{
  "id": "call_custom",
  "type": "custom_tool_call",
  "call_id": "custom_123",
  "name": "my_tool",
  "input": "tool input data"
}
```

## Streaming

When `stream: true` is set, the API returns server-sent events. See the [Streaming Events API documentation](./StreamingEventsAPI.md) for detailed event types and handling.

### Basic Streaming Example

```javascript
const response = await fetch("https://api.openai.com/v1/responses", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  },
  body: JSON.stringify({
    model: "gpt-4o",
    input: "Tell me a story",
    stream: true,
  }),
});

const reader = response.body.getReader();
const decoder = new TextDecoder();

while (true) {
  const { done, value } = await reader.read();
  if (done) break;

  const chunk = decoder.decode(value);
  const lines = chunk.split("\n");

  for (const line of lines) {
    if (line.startsWith("data: ")) {
      const data = line.slice(6);
      if (data === "[DONE]") break;

      const event = JSON.parse(data);
      // Handle event based on type
      console.log(event);
    }
  }
}
```

## Example Use Cases

### Multi-turn Conversation

```javascript
// First turn
const response1 = await createResponse({
  model: "gpt-4o",
  input: "What is the capital of France?",
});

// Second turn using previous_response_id
const response2 = await createResponse({
  model: "gpt-4o",
  input: "What is its population?",
  previous_response_id: response1.id,
});
```

### Using Tools

```javascript
const response = await createResponse({
  model: "gpt-4o",
  input: "Search for recent news about AI",
  tools: [
    {
      type: "web_search",
      search_context_size: "high",
    },
  ],
  tool_choice: "auto",
});
```

### Structured Output with JSON Schema

```javascript
const response = await createResponse({
  model: "gpt-4o",
  input: "Generate a person profile",
  text: {
    format: {
      type: "json_schema",
      name: "person_profile",
      schema: {
        type: "object",
        properties: {
          name: { type: "string" },
          age: { type: "number" },
          email: { type: "string", format: "email" },
        },
        required: ["name", "age", "email"],
      },
      strict: true,
    },
  },
});
```

### Background Processing

```javascript
// Start a background task
const response = await createResponse({
  model: "gpt-4o",
  input: "Analyze this large dataset...",
  background: true,
});

// Check status later
const status = await getResponse(response.id);

// Cancel if needed
if (status.status === "in_progress") {
  await cancelResponse(response.id);
}
```

## Best Practices

1. **Use `previous_response_id` for conversations** - This maintains context efficiently without resending entire conversation history
2. **Set appropriate `max_output_tokens`** - Control costs and response length
3. **Use `stream: true` for real-time experiences** - Improves perceived latency
4. **Leverage caching with `prompt_cache_key`** - Optimize for repeated similar requests
5. **Use structured outputs for reliable JSON** - Ensures valid, schema-compliant responses
6. **Set `safety_identifier` for user tracking** - Helps with abuse detection (hash user emails/IDs)
7. **Choose appropriate `service_tier`** - Balance cost and performance needs
8. **Use `metadata` for request tracking** - Attach custom identifiers for analytics

## Rate Limits and Error Handling

Handle common error codes:

- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (invalid API key)
- `429` - Rate limit exceeded
- `500` - Internal server error
- `503` - Service unavailable

Example error handling:

```javascript
try {
  const response = await createResponse(params);
} catch (error) {
  if (error.status === 429) {
    // Implement exponential backoff
    await sleep(1000 * Math.pow(2, retryCount));
    // Retry request
  } else if (error.status === 400) {
    console.error("Invalid request:", error.message);
  }
}
```

## See Also

- [Streaming Events API](./StreamingEventsAPI.md)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Models Documentation](https://platform.openai.com/docs/models)
- [Pricing](https://openai.com/pricing)
