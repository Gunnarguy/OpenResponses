# Advanced Topics

This section covers advanced features and concepts for building sophisticated applications with the OpenAI API.

## Overview

- **[Connectors and MCP Servers](#connectors-and-mcp-servers):** Extend model capabilities by connecting to external services.
- **[Prompt Caching](#prompt-caching):** Reduce latency and cost for repetitive prompts.
- **[Reasoning Models](#reasoning-models):** Leverage models designed for complex problem-solving and planning.
- **[Streaming](#streaming):** Receive model outputs as they are generated for real-time applications.
- **[Structured Outputs](#structured-outputs):** Ensure model responses conform to a specific JSON schema.

---

## Connectors and MCP Servers

Connectors and remote Model Context Protocol (MCP) servers give models new capabilities by allowing them to connect to and control external services. This enables you to build powerful integrations with services like Google Workspace, Dropbox, or your own custom APIs.

### Using a Remote MCP Server

You can connect to any server on the public internet that implements a remote MCP server. This requires providing a `server_url` and potentially an OAuth token for authorization.

**Important:** You must trust any remote MCP server you use, as a malicious server could exfiltrate sensitive data from the model's context.

```python
from openai import OpenAI

client = OpenAI()

resp = client.responses.create(
    model="gpt-5",
    tools=[
        {
            "type": "mcp",
            "server_label": "dmcp",
            "server_description": "A Dungeons and Dragons MCP server to assist with dice rolling.",
            "server_url": "https://dmcp-server.deno.dev/sse",
            "require_approval": "never", # Use with caution
        },
    ],
    input="Roll 2d4+1",
)

print(resp.output_text)
```

### Using Connectors

Connectors are OpenAI-maintained MCP wrappers for popular services. Instead of a `server_url`, you provide a `connector_id` and an OAuth access token.

Available connectors include:

- Dropbox: `connector_dropbox`
- Gmail: `connector_gmail`
- Google Calendar: `connector_googlecalendar`
- And more.

---

## Prompt Caching

Prompt caching reduces latency and cost by caching the results of frequently used prompt prefixes. This works automatically for all API requests on supported models (`gpt-4o` and newer) for prompts of 1024 tokens or longer.

### How it Works

1.  **Cache Routing:** Requests are routed to a server based on a hash of the prompt's initial prefix.
2.  **Cache Lookup:** The system checks if the prefix exists in the cache.
3.  **Cache Hit/Miss:** If a match is found (hit), the cached result is used, saving time and cost. If not (miss), the full prompt is processed and the prefix is cached for future use.

To optimize for caching, place static content (instructions, examples) at the beginning of your prompt and dynamic content (user input) at the end.

---

## Reasoning Models

Reasoning models like `gpt-5` are trained to perform complex problem-solving by generating an internal "chain of thought" before providing an answer. They excel at coding, scientific reasoning, and multi-step planning.

### Using a Reasoning Model

You can enable reasoning by setting the `reasoning.effort` parameter in your request.

```python
from openai import OpenAI

client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "medium"}, # Can be low, medium, or high
    input=[
        {
            "role": "user",
            "content": "Plan a 3-day trip to Tokyo, focusing on historical sites."
        }
    ]
)

print(response.output_text)
```

Reasoning models introduce **reasoning tokens**, which are billed as output tokens but are not visible in the final response. Ensure you allocate enough space in the context window for these tokens.

---

## Streaming

Streaming allows you to receive the model's response as it's being generated, which is essential for real-time applications. To enable streaming, set `stream=True` in your request.

The API uses semantic server-sent events. You can listen for specific event types, such as `response.output_text.delta`, to process the response as it comes in.

```python
from openai import OpenAI
client = OpenAI()

stream = client.responses.create(
    model="gpt-5",
    input=[{"role": "user", "content": "Write a short story about a robot who discovers music."}],
    stream=True,
)

for event in stream:
    # Check for text delta events and print the content
    if event.type == 'response.output_text.delta':
        print(event.text_delta.text, end="")
```

---

## Structured Outputs

Structured Outputs ensure that the model's response conforms to a JSON schema you define. This is useful for applications that need reliable, machine-readable data.

### Using Structured Outputs

You can define a schema using JSON Schema, or with libraries like Pydantic in Python.

```python
from openai import OpenAI
from pydantic import BaseModel

client = OpenAI()

class UserProfile(BaseModel):
    name: str
    email: str
    age: int

response = client.responses.parse(
    model="gpt-4o-2024-08-06",
    input=[
        {"role": "system", "content": "Extract the user's information."},
        {"role": "user", "content": "My name is John Doe, I'm 30, and my email is john.doe@example.com."},
    ],
    text_format=UserProfile,
)

user_profile = response.output_parsed
print(user_profile.model_dump_json(indent=2))
```

This feature eliminates the need for complex prompt engineering to enforce a specific output format and provides reliable, type-safe results.
