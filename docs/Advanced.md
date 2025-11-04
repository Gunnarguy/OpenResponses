# Advanced Topics

---

**[2025-09-13] Beta Pause Note:**
This project is paused in a "super beta" state. Major recent work includes:

- Ultra-strict computer-use mode (toggle disables all app-side helpers; see below)
- Full production-ready computer-use tool (all official actions, robust error handling, native iOS WebView)
- Model/tool compatibility gating: computer-use is only available on the dedicated model (`computer-use-preview`), not gpt-4o/gpt-4-turbo/etc.
- All changes are documented for easy resumption—see ROADMAP.md and CASE_STUDY.md for technical details.

**To resume:** Review this section, ROADMAP.md, and the case study for a full summary of what’s done and what’s next.

This section covers advanced features and concepts for building sophisticated applications with the OpenAI API.

## Overview

- **[Prompt Caching](#prompt-caching):** Reduce latency and cost for repetitive prompts.
- **[Reasoning Models](#reasoning-models):** Leverage models designed for complex problem-solving and planning.
- **[Streaming](#streaming):** Receive model outputs as they are generated for real-time applications.
- **[Structured Outputs](#structured-outputs):** Ensure model responses conform to a specific JSON schema.

---

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

In the app, go to **Settings → MCP** to manage these integrations. The new **Enable MCP Tools** switch lets you temporarily suspend MCP tool calls without deleting stored credentials or configuration. Re-enable the toggle when you want the model to resume calling the connector or remote server.

---

## Prompt Caching

Prompt caching reduces latency and cost by caching the results of frequently used prompt prefixes. This works automatically for all API requests on supported models (`gpt-4o` and newer) for prompts of 1024 tokens or longer.

### How it Works

1. **Cache Routing:** Requests are routed to a server based on a hash of the prompt's initial prefix.
2. **Cache Lookup:** The system checks if the prefix exists in the cache.
3. **Cache Hit/Miss:** If a match is found (hit), the cached result is used, saving time and cost. If not (miss), the full prompt is processed and the prefix is cached for future use.

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

---

## Ultra-strict Computer Use Mode

When you need the agent to follow the model's exact browser actions with zero app-side helpers, enable:

- Settings → Debugging → “Ultra-strict computer use (no helpers)”

What it disables:

- Pre-navigation URL derivation for initial screenshots/clicks
- Intent-aware search submission on known engines
- Click-by-text overrides (finding coordinates by visible text)
- Aggressive loop-prevention heuristics around repeated screenshots/waits

What remains:

- Official computer-use action loop with screenshots and current_url
- Safety checks and user approvals
- Error handling and basic UI updates

Use this mode for purist behavior, regression testing, or when you want to evaluate the raw model policy without app-side nudges.

---

## Quieting Simulator Log Noise (Optional)

When running on iOS Simulator, you may see benign logs such as `eligibility.plist` missing or CoreHaptics warnings. These do not affect app behavior.

- In Xcode, use the Console filter to exclude subsystems like `com.apple.CoreHaptics` and messages containing `eligibility.plist`.
- To broadly reduce OS log chatter in the Run console, you can set an environment variable in your Run scheme:
  - Add `OS_ACTIVITY_MODE = disable` under Scheme > Run > Arguments > Environment Variables.

This only affects developer ergonomics in Xcode and is not required for production.
