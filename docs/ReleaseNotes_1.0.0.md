# Release Notes - Version 1.0.0

**Release Date:** Q4 2025

## Welcome to OpenResponses 1.0

OpenResponses is a powerful iOS client for interacting with OpenAI's latest language models and tools. Built with SwiftUI and designed for iOS 17+, it provides a native, privacy-focused interface for advanced AI conversations.

## Key Features

### 🤖 AI Conversations

- **Multiple Model Support:** Choose from gpt-4o, gpt-4o-mini, o1-preview, o1-mini, and more
- **Streaming Responses:** Real-time message streaming with token-by-token display
- **Conversation History:** All conversations stored locally and securely on your device
- **Rich Formatting:** Markdown rendering with code syntax highlighting

### 🛠️ Advanced Tools

- **File Search:** Upload documents to vector stores for AI-powered document search and retrieval
- **Code Interpreter:** Execute Python code with matplotlib support for data analysis and visualization
- **Image Generation:** Create images using DALL-E 3 directly from the chat interface
- **Web Search:** Enable AI to search the web for current information (requires configuration)
- **Computer Use:** Experimental support for AI-controlled computer interactions (preview)

### 🔌 Model Context Protocol (MCP)

- **MCP Integration:** Connect to external tools and data sources via MCP servers
- **Pre-configured Connectors:** Built-in support for popular services
- **Custom Servers:** Add your own MCP servers with custom authentication
- **OAuth Support:** Seamless OAuth flows for supported connectors

### 🎨 Customization

- **Prompt Presets:** Create and save custom system prompts for different use cases
- **Model Configuration:** Adjust temperature, max tokens, and other model parameters
- **Tool Selection:** Enable/disable specific tools per conversation
- **Response Formatting:** Control output structure with JSON schemas and structured outputs

### 🔒 Privacy & Security

- **Local Storage:** All conversations and data stored only on your device
- **Keychain Security:** API keys secured in iOS Keychain with device encryption
- **No Analytics by Default:** Optional analytics can be enabled in settings
- **Open Source:** Full source code available for transparency

### ♿ Accessibility

- **VoiceOver Support:** Full accessibility labels and hints for screen readers
- **Dynamic Type:** Responsive text sizing throughout the app
- **High Contrast:** Support for system accessibility settings

## System Requirements

- iOS 17.0 or later
- iPhone or iPad
- OpenAI API key (obtain from platform.openai.com)

## Getting Started

1. **Install OpenResponses** from the App Store
2. **Enter your OpenAI API key** in Settings when prompted
3. **Choose your model** from the available options
4. **Start chatting** - your conversations are saved automatically

## Privacy

OpenResponses respects your privacy:

- No data collected or transmitted except to OpenAI's API
- API keys stored securely in iOS Keychain
- Conversations never leave your device
- Optional analytics disabled by default

For full details, see our Privacy Policy.

## Known Limitations

- **No Cross-Device Sync:** Conversations are stored locally only
- **Single User:** No multi-user or profile support
- **File Search Limits:** Vector store size limits apply per OpenAI pricing
- **Internet Required:** Active internet connection needed for all AI features

## Feedback & Support

- **GitHub Issues:** <https://github.com/Gunnarguy/OpenResponses/issues>
- **Documentation:** Available in the repository
- **Open Source:** Contributions welcome!

## Future Roadmap

We're working on:

- **Conversations API Integration:** Cloud-synced conversation history
- **Enhanced File Support:** Direct file uploads to conversations
- **Apple Intelligence:** Integration with on-device Apple AI features
- **Additional Models:** Support for new OpenAI model releases

## License

OpenResponses is released under the MIT License. See LICENSE file for details.

## Acknowledgments

Built with:

- SwiftUI
- OpenAI API
- Model Context Protocol (MCP)

Special thanks to the open source community and early testers.

---

**Version:** 1.0.0 (Build 1)  
**Author:** Gunnar Hostetler  
**Repository:** <https://github.com/Gunnarguy/OpenResponses>
