# OpenAI GPT-5.6 Family Integration

*Last Updated: 2026-07-10*

On July 9, 2026, OpenAI released the **GPT-5.6** series. OpenResponses provides comprehensive, day-one support for these models through the standard Responses API.

## Model Tiers

The GPT-5.6 family abandons the "o" and "turbo" naming conventions for a tiered planetary naming scheme:

1. **`gpt-5.6-sol`** (Flagship): The most capable model, optimized for complex reasoning, multi-step coding, and long-horizon agentic workflows. (The generic `gpt-5.6` alias automatically routes to this model).
2. **`gpt-5.6-terra`** (Balanced): A mid-tier model designed to provide a strict balance between intelligence and cost.
3. **`gpt-5.6-luna`** (Cost-Efficient): The fastest, most cost-effective tier optimized for high-volume, lightweight tasks.

### Core Capabilities

- **1.05 Million Context Window**: All models support a massive 1.05M token context.
- **128K Output Limit**: Can generate up to 128,000 output tokens in a single completion.
- **Image Handling at Scale**: Models now natively accept images at their original dimensions (`auto` or `original` detail configurations).

## New API Parameters & Controls

### Persisted Reasoning & Max Reasoning Effort
GPT-5.6 introduces expanded controls over internal thought processes. 
- `reasoning_effort`: Controls the minimum/target effort (`minimal`, `low`, `medium`, `high`, `xhigh`).
- `max_reasoning_effort`: Hard cap on the depth of the model's internal thought process to prevent runaway token costs on long-horizon reasoning tasks.

OpenResponses dynamically maps both parameters when these models are selected.

### Explicit Prompt Caching Controls
Instead of opaque caching algorithms, GPT-5.6 supports explicit prompt caching with specific breakpoints. Caches have a guaranteed 30-minute minimum life, making repetitive tasks far more cost-effective.

### Multi-Agent Orchestration (Beta)
Within the Responses API, GPT-5.6 natively handles routing between sub-agents and tool loops. (OpenResponses supports standard tool callbacks compatible with this).

### Programmatic Tool Calling
Enhanced support for deterministic model-driven tool execution, allowing the model to chain multiple tools internally before returning the stream.

## Application Support

In OpenResponses, GPT-5.6 models receive the highest priority sorting in the `DynamicModelSelector`. 
Because GPT-5.6 is optimized for long-horizon agentic workflows, the **Computer Use tool** is enabled for all models in the family (`sol`, `terra`, and `luna`).
