# Prompting Guide

Effective prompting is the key to unlocking the full potential of OpenAI models. This guide covers fundamental and advanced techniques for crafting prompts that yield accurate, relevant, and well-structured responses.

## Overview

A prompt is the set of instructions and context you provide to a model to guide its response. It can include:

- **Instructions:** A specific task or command for the model to execute.
- **Context:** External information or additional context to steer the model.
- **Input Data:** The content we want the model to process.
- **Examples:** Preferred output format or style (few-shot prompting).

This guide covers three core areas of prompting:

1.  **[Best Practices](#best-practices):** General principles for writing effective prompts.
2.  **[Structured Outputs](#structured-outputs):** How to get the model to return responses in a specific format, like JSON.
3.  **[Prompt Caching](#prompt-caching):** Techniques for reducing latency and cost by reusing parts of prompts.

---

## Best Practices

Follow these six strategies to get better results from the models. These are not mutually exclusive and can be combined for the best results.

### 1. Write Clear Instructions

Models can't read your mind. Be specific, descriptive, and as detailed as possible about the desired context, outcome, length, format, and style.

- **Bad:** "Summarize the meeting notes."
- **Good:** "Summarize the meeting notes into a single paragraph. Then, write a list of the action items and the person responsible for each."

To get structured output like JSON, specify the exact schema you need. See the [Structured Outputs](#structured-outputs) section for more details.

### 2. Provide Reference Text

Models can sometimes invent answers, especially when asked about esoteric topics or for citations. Providing reference text from a trusted source helps the model answer with less "hallucination."

- **Bad:** "Who is Emperor Aurelius?"
- **Good:** "According to the provided text, who was Emperor Aurelius and what were his main accomplishments? [Insert text about Marcus Aurelius here]"

### 3. Split Complex Tasks into Simpler Subtasks

Just as in software engineering, it's better to break down complex tasks into a series of simpler prompts. This reduces error rates and allows for more focused instructions. You can chain the output of earlier prompts as input for later ones.

- **Complex Task:** "Summarize the customer feedback, identify the top 3 complaints, and draft a polite response to each."
- **Subtask 1:** "Summarize this customer feedback: [feedback text]"
- **Subtask 2:** "Given this summary, what are the top 3 complaints?"
- **Subtask 3:** "Draft a polite, non-committal response to this complaint: [complaint text]"

### 4. Give the Model "Time to Think"

Models make more reasoning errors when forced to answer instantly. Encourage a "chain of thought" or a step-by-step reasoning process before reaching a final conclusion.

- **Bad:** "Is the student's solution correct? [Student's solution]"
- **Good:** "First, work out your own solution to the problem. Then, compare your solution to the student's solution and evaluate if the student's solution is correct. Before you decide if the solution is correct, do the problem yourself."

### 5. Use External Tools

Compensate for model weaknesses by giving them access to tools. For example, a `web_search` tool can provide up-to-date information, and a `code_interpreter` can handle precise mathematical calculations. The [Responses API](/docs/api-reference/responses) makes it easy to integrate tools.

### 6. Test Changes Systematically

Improving prompt performance requires iterative testing. Establish a comprehensive evaluation suite (an "eval") with a diverse set of test cases to measure the impact of prompt changes. This helps ensure that a change that improves performance on one case doesn't degrade it on others.

---

## Structured Outputs

You can force the model to output valid, schema-compliant JSON. This is incredibly useful for building applications that need reliable, machine-readable data.

### How it Works

The Responses API provides a `response_format` parameter. When you set `response_format={"type": "json_object"}` and provide a JSON schema, the model is constrained to only output tokens that conform to that schema.

**Key Features:**

- **Guaranteed JSON:** The output is always valid JSON.
- **Schema Adherence:** The JSON will follow the structure you define.
- **Reduced Hallucination:** The model is less likely to generate fields not in the schema.

### Example: Extracting User Data

```python
from openai import OpenAI
import json

client = OpenAI()

# Define the JSON schema for the output
user_schema = {
    "type": "object",
    "properties": {
        "name": {"type": "string", "description": "The user's full name."},
        "email": {"type": "string", "format": "email", "description": "The user's email address."},
        "age": {"type": "integer", "description": "The user's age."},
    },
    "required": ["name", "email"],
}

response = client.responses.create(
    model="gpt-5",
    input="Extract user info from this text: 'John Doe is 30 years old and his email is john.doe@example.com'",
    response_format={
        "type": "json_object",
        "schema": user_schema
    }
)

# The output_text will be a valid JSON string
user_data = json.loads(response.output_text)
print(user_data)
# Expected output:
# {'name': 'John Doe', 'email': 'john.doe@example.com', 'age': 30}
```

This feature is a powerful alternative to traditional function calling for cases where you only need structured data extraction.

---

## Prompt Caching

Prompt Caching is a feature that saves time and reduces costs for repeated prompts. When enabled, the API caches the hidden state (KV cache) generated from the prompt tokens. Subsequent calls with the same cached prompt can start generating tokens immediately, bypassing the initial processing step.

### Use Cases

- **Interactive Applications:** When a user is repeatedly asking questions about the same long document.
- **Chain of Thought:** Caching the initial instruction and context allows for rapid exploration of different questions or reasoning paths.
- **Few-Shot Prompting:** Cache the examples to speed up inference on new inputs.

### How to Use It

1.  **First Request:** Make an API call with `cache=True`. The response will include a `cache_id`.
2.  **Subsequent Requests:** Use the `cache_id` in your next request. The model will reuse the cached state.

**Example:**

```python
from openai import OpenAI

client = OpenAI()

# First call, with caching enabled
response1 = client.responses.create(
    model="gpt-5",
    input="You are a helpful assistant. The user is asking about the provided document. [Insert very long document here]",
    cache=True
)
cache_id = response1.cache_id

# Now, ask a question about the document
response2 = client.responses.create(
    model="gpt-5",
    cache_id=cache_id,
    input="What is the main conclusion of the document?"
)

# The second call is much faster because the document is already processed.
print(response2.output_text)
```

Prompt Caching provides a significant performance boost for applications with repetitive or context-heavy prompts.
