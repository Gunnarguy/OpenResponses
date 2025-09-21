# Using Tools

Extend model capabilities with built-in tools to search the web, retrieve files, call functions, or access third-party services.

## Overview

When generating model responses, you can enable tools to give the model access to external capabilities. The model can then choose to use these tools when appropriate to provide a more accurate or comprehensive response.

This guide covers the following tools:

- [Web Search](#web-search)
- [File Search](#file-search)
- [Function Calling](#function-calling)
- [Code Interpreter](#code-interpreter)
- [Image Generation](#image-generation)

---

## Web Search

Web search allows models to access up-to-date information from the internet and provide answers with sourced citations.

### Enabling Web Search

To enable web search, include it in the `tools` array of your API request.

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    tools=[{"type": "web_search"}],
    input="What was a positive news story from today?"
)

print(response.output_text)
```

### Output and Citations

Model responses using web search will include a `web_search_call` output item and a `message` item with the text result and `url_citation` annotations. Your UI must make these citations clearly visible and clickable.

### Domain Filtering

You can limit results to a specific set of up to 20 domains using the `filters` parameter.

```python
response = client.responses.create(
    model="gpt-5",
    tools=[{
        "type": "web_search",
        "filters": {
            "allowed_domains": [
                "example.com",
                "anotherexample.org",
            ]
        }
    }],
    input="What's new with our partners?"
)
```

---

## File Search

File search allows the model to search the contents of your uploaded files to inform its responses. This is useful for building assistants that can answer questions about specific documents.

### Enabling File Search

First, upload files using the Files API and associate them with a vector store. Then, you can enable file search in your API call.

```python
from openai import OpenAI
client = OpenAI()

# First, create a vector store and add files to it
vector_store = client.beta.vector_stores.create(name="Financial Statements")
file_paths = ["annual_report_2023.pdf", "q1_2024_earnings.pdf"]
file_streams = [open(path, "rb") for path in file_paths]
client.beta.vector_stores.files.upload_and_poll(
  vector_store_id=vector_store.id, files=file_streams
)

# Then, use the vector store in your response creation
response = client.responses.create(
    model="gpt-4.1",
    input="What were the key takeaways from the latest earnings report?",
    tools=[{
        "type": "file_search",
        "vector_store_ids": [vector_store.id]
    }]
)
print(response.output_text)
```

---

## Function Calling

Function calling allows you to describe your application's functions to the model, which can then intelligently decide to call those functions and return the output to you.

### Defining and Calling Functions

You define functions in the `tools` parameter and the model will return a `function_call` object if it decides to use one.

```python
from openai import OpenAI
import json

client = OpenAI()

def get_current_weather(location):
    # Dummy function for example
    return {"temperature": "72", "unit": "fahrenheit"}

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_current_weather",
            "description": "Get the current weather in a given location",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "The city and state, e.g. San Francisco, CA",
                    },
                },
                "required": ["location"],
            },
        }
    }
]

response = client.responses.create(
    model="gpt-5",
    input=[{"role": "user", "content": "What's the weather like in Boston?"}],
    tools=tools,
)

# This example assumes the model decides to call the function.
# In a real application, you would need to handle the function call output.
for output in response.output:
    if output.type == 'function_call':
        function_call = output.function
        if function_call.name == "get_current_weather":
            location = json.loads(function_call.arguments)["location"]
            weather = get_current_weather(location)
            # You would then send this back to the model in a new request
            print(f"Weather in {location}: {weather}")

```

---

## Code Interpreter

The Code Interpreter tool allows the model to write and run Python code in a sandboxed environment. This is useful for data analysis, solving math problems, and more.

### Enabling Code Interpreter

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    tools=[{"type": "code_interpreter"}],
    input="What is the result of 2 to the power of 10?",
)

print(response.output_text)
```

---

## Image Generation

The image generation tool allows you to generate images using a text prompt, leveraging the `gpt-image-1` model.

### Enabling Image Generation

```python
from openai import OpenAI
import base64

client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    input="Generate an image of a futuristic city skyline at sunset.",
    tools=[{"type": "image_generation"}],
)

# Save the image to a file
image_data = [
    output.result
    for output in response.output
    if output.type == "image_generation_call"
]

if image_data:
    image_base64 = image_data[0]
    with open("city_skyline.png", "wb") as f:
        f.write(base64.b64decode(image_base64))
```

---

## Function Calling

Function calling allows you to describe functions to the models in your API requests, and have the model intelligently decide when to use them. The model will generate a JSON object containing the arguments for the functions you define. This is a powerful way to connect the model's capabilities with your own application's code and external APIs.

### How it works

1.  **Define your functions:** In your API request, describe the functions you want the model to be able to call, including their parameters and what they do.
2.  **Model calls a function:** The model analyzes the user's prompt and, if appropriate, decides to call one of your functions. It then generates a `function_call` object in its response, containing the name of the function and the arguments to use.
3.  **You execute the function:** Your application code receives the `function_call` object. You then execute your actual function with the provided arguments.
4.  **Provide the result:** You make another API call, appending the result from your function call. This gives the model the context it needs to continue the conversation.

### Example: Getting the weather

**Step 1: Define the function and make the initial request**

```python
from openai import OpenAI

client = OpenAI()

tools = [
    {
        "type": "function",
        "name": "get_current_weather",
        "description": "Get the current weather in a given location",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA",
                },
                "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]},
            },
            "required": ["location"],
        },
    }
]

response = client.responses.create(
    model="gpt-4o",
    input=[{"role": "user", "content": "What's the weather like in Boston?"}],
    tools=tools,
)

# The response will contain a `function_call` output item
print(response.output[0].to_json())
```

**Step 2: Execute your function**

Your code should check the response for a `function_call`. If it exists, you can parse the arguments and call your local function.

```python
import json

# Example function to get weather
def get_current_weather(location, unit="fahrenheit"):
    """Get the current weather in a given location"""
    weather_info = {
        "location": location,
        "temperature": "72",
        "unit": unit,
        "forecast": ["sunny", "windy"],
    }
    return json.dumps(weather_info)

# Pretend we got this from the model's response
function_call_args = json.loads('{"location": "Boston, MA"}')

# Call the function with the model's arguments
function_result = get_current_weather(
    location=function_call_args.get("location"),
)
```

**Step 3: Provide the result back to the model**

Append the function result to the conversation history and make another API call.

```python
# Append the function call and its result to the conversation
# This example uses manual state management.
# See the Conversation State guide for more details.

new_input = [
    {"role": "user", "content": "What's the weather like in Boston?"},
    response.output[0], # The original function_call from the model
    {
        "type": "function_result",
        "tool_call_id": response.output[0].id,
        "function_name": "get_current_weather",
        "result": function_result,
    }
]

final_response = client.responses.create(
    model="gpt-4o",
    input=new_input,
    tools=tools,
)

print(final_response.output_text)
# Expected output: "The weather in Boston is currently 72°F and it is sunny and windy."
```

---

## Web Search

Web search allows models to access up-to-date information from the internet and provide answers with sourced citations.

### Enabling Web Search

To enable this, use the `web_search` tool in the Responses API.

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    tools=[{"type": "web_search"}],
    input="What was a positive news story from today?"
)

print(response.output_text)
```

### Output and Citations

Model responses that use web search will include:

1.  A `web_search_call` output item.
2.  A `message` output item containing the text result and `url_citation` annotations.

Your user interface **must** make these inline citations clearly visible and clickable.

### Domain Filtering

You can limit results to a specific set of up to 20 domains using the `filters` parameter.

```python
response = client.responses.create(
    model="gpt-5",
    tools=[{
        "type": "web_search",
        "filters": {
            "allowed_domains": [
                "pubmed.ncbi.nlm.nih.gov",
                "www.who.int",
                "www.cdc.gov",
            ]
        }
    }],
    input="Latest research on semaglutide."
)
```

---

## File Search

File search allows the model to search the contents of files you've uploaded to OpenAI. This is useful for building applications where the model needs to reference specific knowledge provided by you.

### How it works

1.  **Upload Files:** Use the [Files API](/docs/api-reference/files) to upload your documents.
2.  **Create a Vector Store:** Group your files into a [Vector Store](/docs/api-reference/vector-stores). This prepares your files for efficient searching.
3.  **Enable File Search:** In your API call, specify the `file_search` tool and provide the `vector_store_ids` you want to search.

### Example

```python
from openai import OpenAI
client = OpenAI()

# First, upload files and create a vector store (not shown here).
# Let's assume you have a vector_store_id = "vs_abc123"

response = client.responses.create(
    model="gpt-4.1",
    input="What is deep research by OpenAI?",
    tools=[{
        "type": "file_search",
        "vector_store_ids": ["vs_abc123"]
    }]
)
print(response.output_text)
```

The model will automatically search the specified vector stores to find relevant content to answer the user's question. The response will include citations referencing the source files.

---

## Code Interpreter

Code Interpreter allows the model to write and run Python code in a sandboxed execution environment. This is useful for a variety of tasks, including data analysis, solving math problems, and creating visualizations.

### Enabling Code Interpreter

To enable Code Interpreter, add it to the `tools` list in your API request.

```python
from openai import OpenAI
client = OpenAI()

response = client.responses.create(
    model="gpt-4o",
    tools=[{"type": "code_interpreter"}],
    input="Plot the sine function from -5 to 5.",
)

# The response will contain an `image_file` in the content
# if the code generates a plot.
for item in response.output:
    if item.type == "message":
        for content_part in item.content:
            if content_part.type == "image_file":
                # process the image file
                print(f"Image generated: {content_part.image_file.file_id}")
```

When the model decides to use Code Interpreter, it will generate a `code_interpreter_call` in the response, which includes the Python code it intends to run. The results, including any text output or generated images, will be provided in a subsequent message.

---

## Agentic Tools

Agentic tools empower the model to perform complex, multi-step tasks by interacting with a computer environment. This is the foundation for building AI agents that can carry out sophisticated workflows.

### The `computer` Tool

The primary agentic tool is `computer`. When enabled, the model can perform actions like clicking, typing, scrolling, and navigating on a virtual browser interface. **OpenResponses features a complete, production-ready implementation** with 100% action coverage, enhanced reliability features, and comprehensive error handling.

**Current Status**: ✅ **Production Ready** - All computer use functionality is fully implemented and tested.

### Building Agents

An "agent" is a system that:

1.  **Perceives** its environment (e.g., reads the content of a webpage).
2.  **Reasons** about the next best action to achieve a goal.
3.  **Acts** by using available tools (e.g., clicks a button, types in a form).

Building a robust agent requires careful prompt engineering, where you define the agent's goals, constraints, and available tools. Reasoning models like `gpt-5` are particularly well-suited for agentic tasks due to their advanced planning capabilities.

### Example Agentic Workflow

A simple agentic workflow might look like this:

1.  **User Prompt:** "Book a flight from SFO to JFK for next Tuesday."
2.  **Model Plan (Reasoning):**
    - Navigate to a flight booking website.
    - Enter "SFO" in the departure field.
    - Enter "JFK" in the arrival field.
    - Calculate next Tuesday's date and enter it.
    - Click the "Search" button.
    - Analyze the results and select the best option.
3.  **Model Actions (using `computer` tool):**
    - `{ "type": "computer_call", "action": "navigate", "url": "https://example-flights.com" }`
    - `{ "type": "computer_call", "action": "type", "selector": "#departure", "text": "SFO" }`
    - ...and so on.

Each action is sent to the environment, and the result (e.g., the new state of the webpage) is fed back to the model, allowing it to perceive the outcome of its action and plan the next step.
