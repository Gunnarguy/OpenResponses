# Streaming API responses

Learn how to stream model responses from the OpenAI API using server-sent events.

By default, when you make a request to the OpenAI API, we generate the model's entire output before sending it back in a single HTTP response. When generating long outputs, waiting for a response can take time. Streaming responses lets you start printing or processing the beginning of the model's output while it continues generating the full response.

## Enable streaming

To start streaming responses, set `stream=True` in your request to the Responses endpoint:

```javascript
import { OpenAI } from "openai";
const client = new OpenAI();

const stream = await client.responses.create({
  model: "gpt-5",
  input: [
    {
      role: "user",
      content: "Say 'double bubble bath' ten times fast.",
    },
  ],
  stream: true,
});

for await (const event of stream) {
  console.log(event);
}
```

```python
from openai import OpenAI
client = OpenAI()

stream = client.responses.create(
    model="gpt-5",
    input=[
        {
            "role": "user",
            "content": "Say 'double bubble bath' ten times fast.",
        },
    ],
    stream=True,
)

for event in stream:
    print(event)
```

The Responses API uses semantic events for streaming. Each event is typed with a predefined schema, so you can listen for events you care about.

For a full list of event types, see the [API reference for streaming](/docs/api-reference/responses-streaming). Here are a few examples:

```python
type StreamingEvent =
	| ResponseCreatedEvent
	| ResponseInProgressEvent
	| ResponseFailedEvent
	| ResponseCompletedEvent
	| ResponseOutputItemAdded
	| ResponseOutputItemDone
	| ResponseContentPartAdded
	| ResponseContentPartDone
	| ResponseOutputTextDelta
	| ResponseOutputTextAnnotationAdded
	| ResponseTextDone
	| ResponseRefusalDelta
	| ResponseRefusalDone
	| ResponseFunctionCallArgumentsDelta
	| ResponseFunctionCallArgumentsDone
	| ResponseFileSearchCallInProgress
	| ResponseFileSearchCallSearching
	| ResponseFileSearchCallCompleted
	| ResponseCodeInterpreterInProgress
	| ResponseCodeInterpreterCallCodeDelta
	| ResponseCodeInterpreterCallCodeDone
	| ResponseCodeInterpreterCallInterpreting
	| ResponseCodeInterpreterCallCompleted
	| Error
```

## Read the responses

If you're using our SDK, every event is a typed instance. You can also identity individual events using the `type` property of the event.

Some key lifecycle events are emitted only once, while others are emitted multiple times as the response is generated. Common events to listen for when streaming text are:

```text
- `response.created`
- `response.output_text.delta`
- `response.completed`
- `error`
```

For a full list of events you can listen for, see the [API reference for streaming](/docs/api-reference/responses-streaming).

## Streaming Feedback in OpenResponses

The OpenResponses app provides comprehensive visual feedback during streaming to keep you informed of what's happening:

### Typing Indicator

- **Blinking cursor**: A animated cursor appears in the assistant's message while content is being generated
- **Token estimation**: Live token count updates show you the current usage alongside the cursor
- **Visual continuity**: The cursor provides clear indication that the response is actively streaming

### Activity Feed

- **Real-time updates**: Toggle the activity details button (chevron icon) to see a live feed of what's happening behind the scenes
- **Detailed insights**: The activity feed shows bullet-point updates for:
  - Content generation progress
  - Tool call executions (web search, file operations, etc.)
  - Reasoning steps and model thinking
  - Rate limiting and API status updates
- **Toggle visibility**: Expand or collapse the activity feed without interrupting the streaming process
- **Persistent state**: Activity feed maintains your preferred visibility setting across conversations

### Status Integration

- **Unified display**: Streaming feedback integrates seamlessly with existing status chips and system messages
- **Non-intrusive design**: All feedback elements are designed to inform without overwhelming the chat interface
- **Accessibility**: Full VoiceOver support ensures streaming feedback works with assistive technologies

This multi-layered feedback system ensures you're never left wondering if the app is working - you can see exactly what's happening at every step of the streaming process.

## Advanced use cases

For more advanced use cases, like streaming tool calls, check out the following dedicated guides:

- [Streaming function calls](/docs/guides/function-calling#streaming)
- [Streaming structured output](/docs/guides/structured-outputs#streaming)

## Moderation risk

Note that streaming the model's output in a production application makes it more difficult to moderate the content of the completions, as partial completions may be more difficult to evaluate. This may have implications for approved usage.

Was this page useful?
