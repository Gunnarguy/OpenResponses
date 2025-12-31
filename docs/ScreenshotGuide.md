# Screenshot Planning Guide

This document provides guidance for creating compelling App Store screenshots for OpenResponses 1.0.0.

## Required Screenshot Sizes

Per Apple's requirements:

- **iPhone 6.9" Display** (1320 x 2868 pixels) - iPhone 16 Pro Max, 15 Pro Max, 14 Pro Max
- **iPhone 6.7" Display** (1290 x 2796 pixels) - iPhone 16 Plus, 15 Plus, 14 Plus
- Optional: iPhone 6.5" (1242 x 2688) for older devices
- Optional: iPad Pro 13" (2048 x 2732) if supporting iPad

## Screenshot Strategy

### 1. Hero Shot - Streaming AI Conversation

**Scene:** ChatView with active streaming response showing code execution

**Content:**
- User message: "Analyze this sales data and create a visualization"
- Streaming response with:
  - Code Interpreter badge visible
  - Python code snippet in markdown formatting
  - Generated matplotlib chart showing data visualization
  - Status indicator showing "Executing code..."

**UI Elements to Show:**
- Clean conversation bubbles
- Syntax-highlighted code block
- Image preview of generated chart
- Model badge (gpt-4o) in status bar
- Dark mode aesthetic

**Annotations:**
- "Real-time streaming responses"
- "Code execution with visualizations"

### 2. Model Configuration

**Scene:** Settings > Model tab with configuration options

**Content:**
- Model selector showing available models (GPT-4o, o1, o3-mini)
- Temperature slider at mid-range
- Reasoning effort control
- System instructions field with sample prompt
- Toggle switches for streaming and published prompts

**UI Elements:**
- Native iOS form controls
- Clear section headers with SF Symbols
- Professional settings layout

**Annotations:**
- "Full control over AI parameters"
- "Configure every aspect of responses"

### 3. File Management

**Scene:** FileManagerView showing vector store with uploaded files

**Content:**
- Vector store card with status badge ("ready")
- List of 4-5 uploaded files:
  - PDF document icon
  - Markdown file icon
  - Text file icon
  - Image preview
- File search enabled toggle
- Usage statistics (X files, Y tokens)

**UI Elements:**
- Clean card-based layout
- File type icons
- Status indicators
- Action buttons

**Annotations:**
- "Upload documents for AI to search"
- "Vector-powered file search"

### 4. MCP Connector Gallery

**Scene:** MCP Connector Gallery with integration options

**Content:**
- Grid of connector cards:
  - Notion (with logo)
  - Google Drive (with logo)
  - GitHub (with logo)
  - Slack (with logo)
- Each card showing:
  - Provider name
  - Tool count badge
  - "Connect" button or "Connected" status

**UI Elements:**
- Colorful provider logos
- Clean card grid layout
- Category filters at top

**Annotations:**
- "Connect to your favorite services"
- "Extend AI with external tools"

### 5. Tools in Action - Web Search

**Scene:** ChatView showing web search results

**Content:**
- User question: "What are the latest features in iOS 18?"
- AI response with:
  - Web Search badge
  - Answer synthesized from sources
  - Source citations with links
  - Structured markdown formatting

**UI Elements:**
- Web search icon/badge
- Formatted citations
- Link indicators
- Clean typography

**Annotations:**
- "Real-time web search"
- "Verified source citations"

### 6. Prompt Library

**Scene:** Prompt Library view with saved configurations

**Content:**
- List of prompt presets:
  - "Code Assistant" - with description
  - "Data Analyst" - with description
  - "Creative Writer" - with description
  - "Research Helper" - with description
- Each showing:
  - Icon/avatar
  - Name and description
  - Model badge
  - Last used timestamp

**UI Elements:**
- List layout with dividers
- SF Symbol icons
- Subtle metadata
- Swipe actions hint

**Annotations:**
- "Save and reuse configurations"
- "Switch contexts instantly"

### 7. Request Inspector (Developer Feature)

**Scene:** Request Inspector showing formatted JSON payload

**Content:**
- Formatted JSON showing API request structure:
  - Model selection
  - Messages array
  - Tools array with descriptions
  - Parameters (temperature, max_tokens, etc.)
- Syntax highlighting
- Collapsible sections

**UI Elements:**
- Code syntax highlighting
- JSON formatting
- Copy button
- Dark mode code editor aesthetic

**Annotations:**
- "Inspect every API request"
- "Perfect for developers"

### 8. Dark Mode Showcase

**Scene:** Same as Hero Shot but in dark mode

**Content:**
- Mirror of screenshot #1 but with dark appearance
- Show clean contrast and readability
- Highlight visual polish

**Annotations:**
- "Beautiful in light and dark"
- "Native iOS experience"

## Screenshot Creation Workflow

### Option 1: Simulator Screenshots (Recommended)

1. **Set up Xcode Simulator:**
   - Launch iPhone 16 Pro Max simulator (6.9" display)
   - Enable dark mode if needed: Settings > Display & Brightness
   - Set text size to default
   - Clear any existing conversations for clean slate

2. **Prepare Data:**
   - Add sample API key
   - Create test conversations with realistic content
   - Upload sample files to vector stores
   - Configure MCP connectors (or mock the UI states)

3. **Capture Screenshots:**
   - Use Simulator > Save Screen (Cmd+S)
   - Alternatively: `xcrun simctl io booted screenshot filename.png`
   - Capture in PNG format at full resolution

4. **Annotate:**
   - Use design tool (Figma, Sketch, Photoshop) to add text overlays
   - Keep annotations minimal and readable
   - Use consistent typography
   - Maintain Apple's aesthetic guidelines

### Option 2: Device Screenshots

1. **Connect physical iPhone:**
   - Use device with 6.9" or 6.7" display
   - Ensure Airplane Mode ON (hide carrier/WiFi indicators)
   - Set time to 9:41 (Apple convention)
   - Charge to 100% battery

2. **Use Xcode Devices:**
   - Window > Devices and Simulators
   - Select device
   - Take Screenshot button
   - Images saved to Desktop

3. **Post-process:**
   - Crop/frame as needed
   - Add annotations
   - Ensure exact pixel dimensions match requirements

## Text Overlays and Captions

Keep text overlays:

- **Short:** Max 2-3 words per annotation
- **Positioned strategically:** Don't obscure key UI
- **Legible:** High contrast, readable font size
- **Consistent:** Same font, size, and style across all screenshots

**Font Recommendations:**

- SF Pro Display (Apple's system font)
- Weight: Semibold or Bold
- Size: 60-80pt for headlines, 40-50pt for subtext
- Color: White with subtle shadow OR accent color with good contrast

## Localization (Future)

For 1.0.0, screenshots are English-only. Future versions will need:

- Translated UI (if app is localized)
- Translated annotations
- Culturally appropriate sample content

## Accessibility Considerations

Ensure screenshots:

- Have good color contrast
- Don't rely solely on color to convey meaning
- Use readable font sizes
- Show accessible UI elements (not hiding accessibility features)

## Delivery Format

**For App Store Connect:**

- PNG format (no transparency needed)
- Exact pixel dimensions per device size
- No rounded corners (Apple adds those)
- RGB color space
- 72 DPI (screen resolution)

**File naming convention:**

```text
openresponses_1.0_iphone69_01_hero.png
openresponses_1.0_iphone69_02_settings.png
openresponses_1.0_iphone67_01_hero.png
...
```

## Timeline

1. **Day 1:** Set up simulator, prepare data, capture raw screenshots
2. **Day 2:** Design annotations, apply to all screenshots
3. **Day 3:** Review, iterate, export final assets
4. **Day 4:** Upload to App Store Connect, verify appearance

## Resources

- **Sample data generators:** Use ChatGPT to generate realistic conversation samples
- **Design tools:** Figma (free), Sketch, Photoshop, Pixelmator Pro
- **Apple guidelines:** <https://developer.apple.com/app-store/product-page/>
- **Screenshot templates:** Many available on Figma Community

## Notes for Developer

- Consider creating a "demo mode" in the app that pre-populates with beautiful sample data
- Add a debug menu option: "Prepare App Store Screenshots" that:
  - Hides sensitive data
  - Shows idealized UI states
  - Prepopulates with curated content
- Keep screenshot source files (PSD, Figma, etc.) in `AppStoreAssets/screenshots/` for future updates

---

**Status:** Ready for execution
**Last Updated:** 2025-11-08
**Version:** 1.0
