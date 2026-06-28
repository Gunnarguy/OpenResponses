import Foundation

struct ResponseSettingsRegistry {
    static let all: [ResponseSettingDescriptor] = [
        // MARK: - Model and Generation
        ResponseSettingDescriptor(
            promptKeyPathName: "name",
            group: .hidden,
            exposure: .intentionallyHidden(reason: "This is the preset name, not an API field."),
            title: "Preset Name",
            description: "The name of this preset.",
            defaultValueDescription: "Default"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "openAIModel",
            apiField: "model",
            group: .model,
            exposure: .primary,
            title: "Model",
            description: "The OpenAI model to use for this request.",
            defaultValueDescription: "gpt-4o"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "reasoningEffort",
            apiField: "reasoning_effort",
            group: .reasoning,
            exposure: .advanced,
            title: "Reasoning Effort",
            description: "How much effort the model should spend reasoning.",
            defaultValueDescription: "medium",
            validValues: ["none", "minimal", "low", "medium", "high", "xhigh"]
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "reasoningSummary",
            group: .reasoning,
            exposure: .advanced,
            title: "Reasoning Summary",
            description: "How the reasoning process is summarized.",
            defaultValueDescription: "auto",
            validValues: ["auto", "concise", "detailed"]
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "temperature",
            apiField: "temperature",
            group: .model,
            exposure: .primary,
            title: "Temperature",
            description: "Controls randomness.",
            defaultValueDescription: "1.0",
            minValue: 0.0,
            maxValue: 2.0
        ),
        
        // MARK: - Instructions
        ResponseSettingDescriptor(
            promptKeyPathName: "systemInstructions",
            apiField: "messages",
            group: .instructions,
            exposure: .primary,
            title: "System Instructions",
            description: "Top-level instructions defining the assistant's behavior.",
            defaultValueDescription: "You are a helpful assistant."
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "developerInstructions",
            apiField: "messages",
            group: .instructions,
            exposure: .advanced,
            title: "Developer Instructions",
            description: "Developer-level instructions, if supported separately.",
            defaultValueDescription: ""
        ),

        // MARK: - Tools (Web Search)
        ResponseSettingDescriptor(
            promptKeyPathName: "enableWebSearch",
            apiField: "tools",
            group: .tools,
            exposure: .primary,
            title: "Web Search",
            description: "Enable the web search tool.",
            defaultValueDescription: "true"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "webSearchMode",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Search Mode",
            description: "The operational mode for web search.",
            defaultValueDescription: "default",
            requiresTool: "web_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "webSearchInstructions",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Search Instructions",
            description: "Custom instructions specifically for the search tool.",
            defaultValueDescription: "",
            requiresTool: "web_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "webSearchMaxPages",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Max Pages",
            description: "Maximum number of pages to retrieve.",
            defaultValueDescription: "0",
            requiresTool: "web_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "webSearchCrawlDepth",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Crawl Depth",
            description: "How deep to crawl linked pages.",
            defaultValueDescription: "0",
            requiresTool: "web_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "webSearchAllowedDomains",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Allowed Domains",
            description: "Comma-separated list of domains to restrict search to.",
            defaultValueDescription: "",
            requiresTool: "web_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "webSearchBlockedDomains",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Blocked Domains",
            description: "Comma-separated list of domains to block.",
            defaultValueDescription: "",
            requiresTool: "web_search"
        ),
        
        // MARK: - Tools (Code Interpreter)
        ResponseSettingDescriptor(
            promptKeyPathName: "enableCodeInterpreter",
            apiField: "tools",
            group: .tools,
            exposure: .primary,
            title: "Code Interpreter",
            description: "Enable execution of Python code.",
            defaultValueDescription: "true"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "codeInterpreterContainerType",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Container Type",
            description: "The container environment type.",
            defaultValueDescription: "auto",
            requiresTool: "code_interpreter"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "codeInterpreterPreloadFileIds",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Preload File IDs",
            description: "File IDs to mount before execution.",
            defaultValueDescription: "",
            requiresTool: "code_interpreter"
        ),
        
        // MARK: - Tools (Image Generation)
        ResponseSettingDescriptor(
            promptKeyPathName: "enableImageGeneration",
            group: .tools,
            exposure: .primary,
            title: "Image Generation",
            description: "Enable image generation capabilities.",
            defaultValueDescription: "true"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "imageGenerationModel",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Image Model",
            description: "Model used for generation.",
            defaultValueDescription: "dall-e-3",
            requiresTool: "image_generation"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "imageGenerationSize",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Image Size",
            description: "Dimensions of the generated image.",
            defaultValueDescription: "1024x1024",
            requiresTool: "image_generation"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "imageGenerationQuality",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Image Quality",
            description: "Quality level.",
            defaultValueDescription: "standard",
            validValues: ["standard", "hd"],
            requiresTool: "image_generation"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "imageGenerationOutputFormat",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Output Format",
            description: "Image format (url or b64_json).",
            defaultValueDescription: "url",
            requiresTool: "image_generation"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "imageGenerationBackground",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Background Generation",
            description: "Controls background context inclusion.",
            defaultValueDescription: "auto",
            requiresTool: "image_generation"
        ),

        // MARK: - Tools (File Search)
        ResponseSettingDescriptor(
            promptKeyPathName: "enableFileSearch",
            apiField: "tools",
            group: .tools,
            exposure: .primary,
            title: "File Search",
            description: "Search vector stores.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "selectedVectorStoreIds",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Vector Store IDs",
            description: "Stores to search across.",
            defaultValueDescription: "",
            requiresTool: "file_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "fileSearchMaxResults",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Max Search Results",
            description: "Maximum documents to return.",
            defaultValueDescription: "20",
            minValue: 1.0,
            maxValue: 50.0,
            requiresTool: "file_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "fileSearchRanker",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Ranker",
            description: "Ranking algorithm version.",
            defaultValueDescription: "auto",
            validValues: ["auto", "default_2024_08_21"],
            requiresTool: "file_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "fileSearchScoreThreshold",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Score Threshold",
            description: "Minimum relevance score.",
            defaultValueDescription: "0.0",
            minValue: 0.0,
            maxValue: 1.0,
            requiresTool: "file_search"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "fileSearchFiltersJSON",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Search Filters (JSON)",
            description: "Metadata filters in JSON format.",
            defaultValueDescription: "",
            requiresTool: "file_search"
        ),

        // MARK: - Tools (Computer Use)
        ResponseSettingDescriptor(
            promptKeyPathName: "enableComputerUse",
            apiField: "tools",
            group: .tools,
            exposure: .primary,
            title: "Computer Use",
            description: "Allow the model to control an environment.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "ultraStrictComputerUse",
            group: .toolAdvanced,
            exposure: .debug,
            title: "Ultra-Strict Computer Use",
            description: "Disables local helper heuristics for exact model output mapping.",
            defaultValueDescription: "false"
        ),

        // MARK: - Tools (Integrations)
        ResponseSettingDescriptor(
            promptKeyPathName: "enableNotionIntegration",
            group: .tools,
            exposure: .primary,
            title: "Notion Integration",
            description: "Allow fetching data from Notion.",
            defaultValueDescription: "true"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "enableAppleIntegrations",
            group: .tools,
            exposure: .primary,
            title: "Apple Integrations",
            description: "Allow reading calendar, contacts, etc.",
            defaultValueDescription: "true"
        ),

        // MARK: - Tools (MCP)
        ResponseSettingDescriptor(
            promptKeyPathName: "enableMCPTool",
            group: .tools,
            exposure: .primary,
            title: "MCP Servers",
            description: "Enable Model Context Protocol (MCP) servers.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpServerLabel",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Configured via MCP connection flow."),
            title: "MCP Label",
            description: "Label for the MCP connection.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpServerURL",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Configured via MCP connection flow."),
            title: "MCP URL",
            description: "URL for the MCP server.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpHeaders",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Handled securely in keychain."),
            title: "MCP Headers",
            description: "Auth headers for MCP.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpRequireApproval",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Configured via MCP connection flow."),
            title: "MCP Requires Approval",
            description: "Approval mode for MCP calls.",
            defaultValueDescription: "prompt"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpAllowedTools",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Configured via MCP connection flow."),
            title: "MCP Allowed Tools",
            description: "Tools explicitly allowed.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpAuthHeaderKey",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Configured via MCP connection flow."),
            title: "MCP Auth Header Key",
            description: "Header key to use for authentication.",
            defaultValueDescription: "Authorization"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpKeepAuthInHeaders",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Configured via MCP connection flow."),
            title: "MCP Keep Auth in Headers",
            description: "Keep auth in headers alongside top level.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpConnectorId",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Configured via MCP connection flow."),
            title: "MCP Connector ID",
            description: "ID for the connector if used.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "mcpIsConnector",
            group: .toolAdvanced,
            exposure: .intentionallyHidden(reason: "Configured via MCP connection flow."),
            title: "Is MCP Connector",
            description: "Whether this is a connector.",
            defaultValueDescription: "false"
        ),

        // MARK: - Tools (Custom)
        ResponseSettingDescriptor(
            promptKeyPathName: "enableCustomTool",
            group: .tools,
            exposure: .advanced,
            title: "Custom Tool",
            description: "Enable a custom defined tool.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "customToolName",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Custom Tool Name",
            description: "Name of the custom tool.",
            defaultValueDescription: "custom_tool_placeholder",
            requiresTool: "custom"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "customToolDescription",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Custom Tool Description",
            description: "Description of the custom tool.",
            defaultValueDescription: "A placeholder for a custom tool.",
            requiresTool: "custom"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "customToolParametersJSON",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Custom Tool Parameters (JSON)",
            description: "JSON Schema for the custom tool.",
            defaultValueDescription: "{}",
            requiresTool: "custom"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "customToolExecutionType",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Custom Tool Execution",
            description: "How to execute the tool locally.",
            defaultValueDescription: "echo",
            validValues: ["echo", "calculator", "webhook"],
            requiresTool: "custom"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "customToolWebhookURL",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Custom Tool Webhook",
            description: "Webhook URL if execution is set to webhook.",
            defaultValueDescription: "",
            requiresTool: "custom"
        ),

        // MARK: - Location
        ResponseSettingDescriptor(
            promptKeyPathName: "userLocationCity",
            group: .state,
            exposure: .intentionallyHidden(reason: "Resolved automatically at runtime if permitted."),
            title: "City",
            description: "User's city.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "userLocationCountry",
            group: .state,
            exposure: .intentionallyHidden(reason: "Resolved automatically at runtime if permitted."),
            title: "Country",
            description: "User's country.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "userLocationRegion",
            group: .state,
            exposure: .intentionallyHidden(reason: "Resolved automatically at runtime if permitted."),
            title: "Region",
            description: "User's region.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "userLocationTimezone",
            group: .state,
            exposure: .intentionallyHidden(reason: "Resolved automatically at runtime if permitted."),
            title: "Timezone",
            description: "User's timezone.",
            defaultValueDescription: ""
        ),

        // MARK: - Advanced API Settings
        ResponseSettingDescriptor(
            promptKeyPathName: "backgroundMode",
            apiField: "background",
            group: .state,
            exposure: .advanced,
            title: "Background Mode",
            description: "Run the task offline.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "maxOutputTokens",
            apiField: "max_completion_tokens",
            group: .model,
            exposure: .primary,
            title: "Max Output Tokens",
            description: "Maximum tokens the model can generate.",
            defaultValueDescription: "0 (unlimited)"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "maxToolCalls",
            apiField: "max_tool_calls",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Max Tool Calls",
            description: "Maximum number of sequential tool calls allowed.",
            defaultValueDescription: "0 (unlimited)"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "parallelToolCalls",
            apiField: "parallel_tool_calls",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Parallel Tool Calls",
            description: "Allow multiple tool calls at once.",
            defaultValueDescription: "true"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "serviceTier",
            apiField: "service_tier",
            group: .model,
            exposure: .advanced,
            title: "Service Tier",
            description: "Routing tier for the request.",
            defaultValueDescription: "auto",
            validValues: ["auto", "default", "flex", "scale", "priority"]
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "topLogprobs",
            apiField: "top_logprobs",
            group: .model,
            exposure: .advanced,
            title: "Top Logprobs",
            description: "Return probability distribution.",
            defaultValueDescription: "0",
            minValue: 0,
            maxValue: 20
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "topP",
            apiField: "top_p",
            group: .model,
            exposure: .advanced,
            title: "Top P",
            description: "Nucleus sampling threshold.",
            defaultValueDescription: "1.0",
            minValue: 0.0,
            maxValue: 1.0
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "truncationStrategy",
            apiField: "truncation_strategy",
            group: .state,
            exposure: .advanced,
            title: "Truncation Strategy",
            description: "How to manage long context windows.",
            defaultValueDescription: "auto",
            validValues: ["auto", "disabled"]
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "userIdentifier",
            apiField: "user",
            group: .state,
            exposure: .advanced,
            title: "User Identifier",
            description: "A unique identifier representing your end-user.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "storeResponses",
            apiField: "store",
            group: .state,
            exposure: .advanced,
            title: "Store Responses",
            description: "Whether the response should be stored in the OpenAI dashboard.",
            defaultValueDescription: "true"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "streamIncludeUsage",
            apiField: "stream_options",
            group: .streaming,
            exposure: .intentionallyHidden(reason: "Currently not directly supported via stream_options in Responses API."),
            title: "Include Usage",
            description: "Include usage data in stream chunks.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "streamIncludeObfuscation",
            apiField: "stream_options",
            group: .streaming,
            exposure: .advanced,
            title: "Include Obfuscation",
            description: "Include obfuscated tokens in the stream.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "promptCacheKey",
            apiField: "prompt_cache_key",
            group: .cache,
            exposure: .advanced,
            title: "Prompt Cache Key",
            description: "Key for caching the prompt context.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "promptCacheRetention",
            apiField: "prompt_cache_retention",
            group: .cache,
            exposure: .advanced,
            title: "Prompt Cache Retention",
            description: "How long to retain the cached prompt.",
            defaultValueDescription: "auto",
            validValues: ["auto", "in_memory", "24h"]
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "safetyIdentifier",
            apiField: "OpenAI-Safety-Identifier",
            group: .safety,
            exposure: .advanced,
            title: "Safety Identifier",
            description: "A unique identifier used for safety monitoring.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "verbosity",
            group: .output,
            exposure: .advanced,
            title: "Verbosity",
            description: "Target verbosity of the response.",
            defaultValueDescription: "medium",
            validValues: ["low", "medium", "high"]
        ),

        // MARK: - Text Formatting & Structured Output
        ResponseSettingDescriptor(
            promptKeyPathName: "textFormatType",
            apiField: "response_format",
            group: .output,
            exposure: .primary,
            title: "Format Type",
            description: "The format of the response (text, json_object, json_schema).",
            defaultValueDescription: "text",
            validValues: ["text", "json_object", "json_schema"]
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "jsonSchemaName",
            group: .output,
            exposure: .advanced,
            title: "JSON Schema Name",
            description: "Name for the structured output schema.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "jsonSchemaDescription",
            group: .output,
            exposure: .advanced,
            title: "JSON Schema Description",
            description: "Description of the schema.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "jsonSchemaStrict",
            group: .output,
            exposure: .advanced,
            title: "Strict Schema Compliance",
            description: "Whether the model strictly adheres to the schema.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "jsonSchemaContent",
            group: .output,
            exposure: .advanced,
            title: "JSON Schema (Content)",
            description: "The actual JSON schema definition.",
            defaultValueDescription: ""
        ),

        // MARK: - Audio
        ResponseSettingDescriptor(
            promptKeyPathName: "enableAudioInput",
            apiField: "modalities",
            group: .model,
            exposure: .primary,
            title: "Audio Input",
            description: "Allow audio modalities in input.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "enableAudioOutput",
            apiField: "modalities",
            group: .model,
            exposure: .primary,
            title: "Audio Output",
            description: "Request the response in audio format.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "audioVoice",
            apiField: "audio",
            group: .model,
            exposure: .advanced,
            title: "Audio Voice",
            description: "Voice to use for generated audio.",
            defaultValueDescription: "alloy"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "audioFormat",
            apiField: "audio",
            group: .model,
            exposure: .advanced,
            title: "Audio Format",
            description: "Format for audio output (wav, mp3, etc).",
            defaultValueDescription: "wav"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "enableInputModeration",
            group: .safety,
            exposure: .advanced,
            title: "Input Moderation",
            description: "Pre-check input with the moderation endpoint.",
            defaultValueDescription: "false"
        ),

        // MARK: - Includes (Debug/Telemetry)
        ResponseSettingDescriptor(
            promptKeyPathName: "includeCodeInterpreterOutputs",
            group: .debug,
            exposure: .debug,
            title: "Include Code Interpreter Outputs",
            description: "Log Code Interpreter results to the conversation.",
            defaultValueDescription: "true"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "includeComputerCallOutput",
            group: .debug,
            exposure: .debug,
            title: "Include Computer Call Output",
            description: "Log Computer Use screenshots and actions.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "includeFileSearchResults",
            group: .debug,
            exposure: .debug,
            title: "Include File Search Results",
            description: "Log retrieved chunks from vector stores.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "includeWebSearchResults",
            group: .debug,
            exposure: .debug,
            title: "Include Web Search Results",
            description: "Log fetched page contents.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "includeWebSearchSources",
            group: .debug,
            exposure: .debug,
            title: "Include Web Search Sources",
            description: "Log citations and source URLs.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "includeInputImageUrls",
            group: .debug,
            exposure: .debug,
            title: "Include Input Image URLs",
            description: "Keep reference to input images in thread state.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "includeOutputLogprobs",
            group: .debug,
            exposure: .debug,
            title: "Include Output Logprobs",
            description: "Store logprob arrays in local message history.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "includeReasoningContent",
            group: .debug,
            exposure: .debug,
            title: "Include Reasoning Content",
            description: "Show internal thought process when available.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "includeComputerUseOutput",
            group: .debug,
            exposure: .debug,
            title: "Include Computer Use Output",
            description: "Duplicate of includeComputerCallOutput for backwards compatibility.",
            defaultValueDescription: "false"
        ),

        // MARK: - Published Prompts & Extras
        ResponseSettingDescriptor(
            promptKeyPathName: "enableStreaming",
            group: .streaming,
            exposure: .primary,
            title: "Streaming",
            description: "Stream the response token-by-token.",
            defaultValueDescription: "true"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "enablePublishedPrompt",
            group: .legacy,
            exposure: .advanced,
            title: "Use Published Prompt",
            description: "Load system instructions from a published prompt.",
            defaultValueDescription: "false"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "publishedPromptId",
            group: .legacy,
            exposure: .advanced,
            title: "Published Prompt ID",
            description: "The remote prompt ID.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "publishedPromptVersion",
            group: .legacy,
            exposure: .advanced,
            title: "Published Prompt Version",
            description: "The specific version of the prompt.",
            defaultValueDescription: "1"
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "toolChoice",
            apiField: "tool_choice",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Tool Choice",
            description: "Force the model to use a specific tool, or 'auto'.",
            defaultValueDescription: "auto",
            validValues: ["auto", "none", "required"]
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "metadata",
            apiField: "metadata",
            group: .state,
            exposure: .advanced,
            title: "Metadata",
            description: "Custom metadata JSON to attach to the response.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "searchContextSize",
            group: .toolAdvanced,
            exposure: .advanced,
            title: "Search Context Size",
            description: "Amount of text context for search tools.",
            defaultValueDescription: ""
        ),
        ResponseSettingDescriptor(
            promptKeyPathName: "id",
            group: .hidden,
            exposure: .intentionallyHidden(reason: "SwiftUI ID, not related to the API"),
            title: "ID",
            description: "Internal ID",
            defaultValueDescription: ""
        )
    ]
}
