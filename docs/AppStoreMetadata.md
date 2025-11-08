# App Store Connect Metadata

This document contains all the metadata required for OpenResponses 1.0.0 submission to the App Store.

## App Information

**Name:** OpenResponses

**Subtitle:** Intelligent AI Assistant

**Bundle ID:** Gunndamental.OpenResponses

**Version:** 1.0.0

**Build:** 1

**Category:** Productivity

**Secondary Category:** Developer Tools

## Description

**Promotional Text (170 characters):**
Unlock the full power of OpenAI's latest models. Stream responses, run code, generate images, search the web, and connect to your data—all in one beautiful interface.

**Description (4000 characters max):**
OpenResponses is a native iOS application that brings the complete OpenAI API experience to your fingertips. Designed for power users, developers, and AI enthusiasts, it provides direct access to cutting-edge AI capabilities with full control over every parameter.

KEY FEATURES

INTELLIGENT CONVERSATIONS
• Stream responses in real-time with advanced message handling
• Support for all OpenAI models including GPT-4o, o1, o3-mini, and computer-use-preview
• Customize temperature, reasoning effort, and output tokens
• Save and load prompt configurations from your library

AI TOOLS & CAPABILITIES
• Code Interpreter: Execute Python code with automatic visualization
• Web Search: Get real-time information from the internet with source attribution
• Image Generation: Create images directly in conversations (gpt-image-1)
• Computer Use: Advanced automation with computer-use-preview model
• File Search: Upload documents and query them with vector-powered search

FILE MANAGEMENT
• Upload files and create vector stores for document retrieval
• Organize files with metadata and attribute filters
• Configure search parameters for optimal results
• Visual file previews with markdown, code highlighting, and image support

MCP (MODEL CONTEXT PROTOCOL) INTEGRATION
• Connect to external data sources via MCP servers
• Built-in connectors for Google services, Notion, GitHub, and more
• Configure remote MCP servers with custom authentication
• Fine-grained tool approval controls for security

CUSTOMIZATION & CONTROL
• Adjust all API parameters: tool choice, truncation, service tier
• Configure response includes: reasoning content, logprobs, tool outputs
• Set moderation categories and safety thresholds
• Parallel tool calls and background execution mode

APPLE ECOSYSTEM INTEGRATION
• Access Calendars, Contacts, and Reminders via AI tools
• Secure credential storage in iOS Keychain
• Native SwiftUI interface with full accessibility support
• Dark mode and Dynamic Type support

DEVELOPER-FRIENDLY
• Export conversations as JSON for analysis
• Request inspector to preview API payloads
• Detailed streaming event visualization
• Support for published prompts and metadata

PRIVACY & SECURITY
• Your API key never leaves your device
• All credentials stored securely in Keychain
• No analytics or tracking—your data is yours
• Local conversation history with optional export

Whether you're a developer exploring AI capabilities, a power user optimizing workflows, or an AI researcher testing new models, OpenResponses gives you complete control over the OpenAI API.

REQUIREMENTS
• iOS 17.0 or later
• OpenAI API key (sign up at platform.openai.com)
• Optional: MCP server URLs for external integrations

Start your AI journey with full transparency, control, and power.

## Keywords (100 characters max)

openai,gpt,chatgpt,ai,assistant,mcp,code interpreter,web search,developer,productivity,api,streaming

## What's New in 1.0.0

**Release Notes:**
Welcome to OpenResponses 1.0! This is the initial release featuring:

• Complete OpenAI Responses API integration
• Support for all current models (GPT-4o, o1, o3-mini, computer-use-preview)
• Native AI tools: Code Interpreter, Web Search, Image Generation, Computer Use
• File management with vector store support
• MCP integration for external data sources
• Apple ecosystem integration (Calendars, Contacts, Reminders)
• Comprehensive prompt configuration library
• Real-time streaming with detailed event handling
• Secure Keychain credential storage
• Full accessibility and Dark Mode support

## URLs

**Marketing URL:**
<https://github.com/gunnarhostetler/OpenResponses>

**Support URL:**
<https://github.com/gunnarhostetler/OpenResponses/issues>

**Privacy Policy URL:**
<https://github.com/gunnarhostetler/OpenResponses/blob/main/PRIVACY.md>

## App Privacy

**Data Collection:** None

**Data Linked to User:** None

**Data Used to Track User:** None

**Privacy Details:**
OpenResponses does not collect, transmit, or share any user data. All conversations, settings, and credentials are stored locally on your device. API requests are made directly to OpenAI's servers using your personal API key—we never see or log your data.

### Privacy Practices

- **No Analytics:** We don't track usage, crashes, or any user behavior
- **No Account:** No registration or login required
- **Local Storage:** All data stays on your device
- **Direct API:** Requests go straight to OpenAI, never through our servers
- **Keychain Security:** API keys stored using iOS Keychain

## App Store Screenshots

**Required Sizes:**

- iPhone 6.9" (1320 x 2868 pixels) - 3-10 screenshots
- iPhone 6.7" (1290 x 2796 pixels) - 3-10 screenshots
- iPhone 6.5" (1242 x 2688 pixels) - Optional
- iPad Pro 13" (2048 x 2732 pixels) - Optional

**Recommended Screenshots:**

1. **Hero Shot:** ChatView with streaming response showing code interpreter output
2. **Settings Overview:** Model configuration with parameter controls
3. **File Management:** Vector store manager with file uploads
4. **MCP Integration:** Connector gallery showing available integrations
5. **Tools in Action:** Web search results with sources
6. **Prompt Library:** Saved configurations with preview
7. **Request Inspector:** JSON payload view for developers
8. **Dark Mode:** Same ChatView in dark appearance

## Review Notes

**Demo Account:** Not required (users provide their own OpenAI API key)

**Contact Information:**

- First Name: Gunnar
- Last Name: Hostetler
- Email: [Your email for App Review]
- Phone: [Your phone for App Review]

**Review Notes:**

This app requires an OpenAI API key to function. Reviewers can sign up for a free OpenAI account at <https://platform.openai.com> and obtain an API key from the API Keys section.

To test the app:

1. Launch OpenResponses
2. Enter your OpenAI API key when prompted
3. Start a conversation with any message
4. Explore tools via Settings > Tools (enable Code Interpreter, Web Search, etc.)
5. Test MCP integration via Settings > MCP > Browse Connector Gallery

The app makes direct API calls to OpenAI's servers. No backend infrastructure is required. All features work with a valid API key.

**Special Features:**

- MCP servers can be tested using public demo servers
- File uploads require OpenAI account with file API access
- Computer Use preview requires gpt-5 or computer-use-preview model

## Age Rating

**Age Rating:** 4+

**Content Descriptions:**

- None

**Privacy Policy:** Required (link provided above)

## Copyright & Trademark

**Copyright:** © 2025 Gunnar Hostetler

**License:** MIT License (see LICENSE file in repository)

## Export Compliance

**Is your app designed to use cryptography or does it contain or incorporate cryptography?**
No (using standard iOS encryption features only)

## Content Rights

**Does your app contain, display, or access third-party content?**
Yes - Users can access OpenAI's AI models and results

**Do you have all necessary rights to that content?**
Yes - Users provide their own OpenAI API key and accept OpenAI's terms

## Advertising Identifier

**Does this app use the Advertising Identifier (IDFA)?**
No

## App Store Availability

**Territories:** All territories (worldwide)

**Pricing:** Free

**In-App Purchases:** None

**App Bundles:** None

## Version Release

**Release Type:** Manual release

**Phased Release:** Yes (7-day rollout recommended for 1.0)

## Notes for Development Team

1. Update email/phone in Review Notes before submission
2. Create all screenshot sizes (at minimum 6.9" and 6.7" iPhone)
3. Prepare demo video if desired (optional but recommended)
4. Test TestFlight build thoroughly before submitting for review
5. Ensure PRIVACY.md is publicly accessible via GitHub
6. Consider adding a website/landing page for Marketing URL
7. Prepare for common rejection reasons:
   - Ensure privacy policy is complete and accessible
   - Verify all Info.plist privacy descriptions are present
   - Test on multiple device sizes
   - Ensure no crashes on launch or basic flows

## Localization

**Primary Language:** English (U.S.)

**Additional Languages:** None (1.0.0 ships English-only)

Future versions may add:

- Spanish
- French
- German
- Japanese
- Chinese (Simplified)

---

**Last Updated:** 2025-11-08
**Document Version:** 1.0
**App Version:** 1.0.0 (Build 1)
