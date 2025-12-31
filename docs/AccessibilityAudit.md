# Accessibility Audit Checklist

This document provides a comprehensive accessibility checklist for OpenResponses 1.0 to ensure the app meets WCAG 2.1 Level AA standards and Apple's accessibility guidelines.

## Overview

OpenResponses must be usable by people with various abilities including:
- Vision impairments (VoiceOver, larger text)
- Motor impairments (Voice Control, Switch Control)
- Cognitive differences (reduced motion, simplified UI)

## Testing Setup

### Required Tools

1. **VoiceOver** (Built-in)
   - Enable: Settings > Accessibility > VoiceOver
   - Toggle: Triple-click side button (after setup)
   - Gestures: Two-finger swipe for reading, one-finger swipe to navigate

2. **Accessibility Inspector** (Xcode)
   - Open: Xcode > Open Developer Tool > Accessibility Inspector
   - Features: Audit, inspection, simulation

3. **Voice Control** (iOS)
   - Enable: Settings > Accessibility > Voice Control
   - Test hands-free interaction

### Test Devices

- iPhone 16 Pro (6.9" display) - Primary
- iPhone SE (4.7" display) - Small screen
- iPad Pro 13" - Tablet interface

## Audit Checklist

### 1. VoiceOver Testing

#### Chat View (`ChatView.swift`)

- [ ] **Message Bubbles** have descriptive labels
  - User messages: "You said: [content]"
  - Assistant messages: "Assistant said: [content]"
  - System messages: "System: [content]"

- [ ] **Streaming indicator** announces status
  - "Assistant is typing"
  - "Generating response"
  - Updates announced as status changes

- [ ] **Code blocks** are readable
  - Language announced: "Python code block"
  - Content summarized or readable line-by-line
  - Copy button: "Copy code"

- [ ] **Images** have alt text
  - Generated images: Description from context
  - Uploaded images: Filename or user-provided description
  - Thumbnails: "Tap to view full size"

- [ ] **Tool outputs** are announced
  - "Code execution complete: [summary]"
  - "Web search results: [count] sources"
  - "File search found: [count] results"

#### Chat Input (`ChatInputView.swift`)

- [ ] **Text field** has clear label
  - "Message input field"
  - Hint: "Type your message to the AI"

- [ ] **Send button** is labeled
  - "Send message"
  - Disabled state: "Send button disabled, enter a message first"

- [ ] **Attachment button** is clear
  - "Attach file or image"
  - State changes announced

- [ ] **Voice input** (if implemented)
  - "Start voice input"
  - "Recording..."
  - "Stop recording"

#### Settings (`SettingsHomeView.swift`)

- [ ] **Tab navigation** is clear
  - "General settings tab"
  - "Model configuration tab"
  - "Tools settings tab"
  - "MCP integration tab"
  - "Advanced settings tab"

- [ ] **Form controls** have labels
  - Toggles: "Enable Code Interpreter, toggle button, currently on"
  - Sliders: "Temperature, 0.7, adjustable"
  - Pickers: "Select model, GPT-4o selected"
  - Text fields: "OpenAI API Key, secure text field"

- [ ] **Sections** are grouped logically
  - Use `accessibilityElement(children: .combine)` where appropriate
  - Section headers announced

- [ ] **Action buttons** are clear
  - "Save as default"
  - "Reset to defaults"
  - "Test MCP connection"

#### File Manager (`FileManagerView.swift`)

- [ ] **File list** is navigable
  - Each file: "[filename], [type], [size], tap to select"
  - Status indicators: "Ready" / "Processing"

- [ ] **Action buttons** per file
  - "Delete [filename]"
  - "Download [filename]"
  - "View details for [filename]"

- [ ] **Upload button** is clear
  - "Upload new file"
  - Progress announced during upload

#### MCP Gallery (`MCPConnectorGalleryView.swift`)

- [ ] **Connector cards** are descriptive
  - "[Provider name] connector, [tool count] tools available"
  - Connection status: "Connected" / "Not connected"

- [ ] **Connect buttons** announce state
  - "Connect to Notion"
  - After connect: "Connected to Notion successfully"

### 2. Dynamic Type Support

#### Font Scaling Tests

- [ ] **Run app at different text sizes**
  - Settings > Accessibility > Display & Text Size > Larger Text
  - Test at: Default, +2, +4, +7 (maximum)

- [ ] **All text scales appropriately**
  - Use `.font(.body)`, `.font(.headline)` etc.
  - Avoid hardcoded font sizes
  - Use `@ScaledMetric` for custom sizes

- [ ] **Layouts don't break**
  - No clipped text
  - Buttons remain tappable
  - ScrollViews accommodate larger content

#### Code Review

Check for proper font usage:
```swift
// ✅ Good - scales automatically
Text("Hello").font(.body)

// ❌ Bad - fixed size
Text("Hello").font(.system(size: 14))

// ✅ Good - custom scaling
@ScaledMetric var iconSize: CGFloat = 24
Image(systemName: "star").font(.system(size: iconSize))
```

### 3. Color & Contrast

#### High Contrast Mode

- [ ] **Test in High Contrast mode**
  - Settings > Accessibility > Display & Text Size > Increase Contrast
  - All UI elements remain visible
  - Sufficient contrast ratios (4.5:1 for text, 3:1 for UI)

- [ ] **Don't rely on color alone**
  - Use icons + color for status
  - Example: ✓ Green "Connected" not just green text

- [ ] **Dark Mode compatibility**
  - Test all views in dark appearance
  - Ensure proper color adaptation
  - Check semantic colors used correctly

#### Color Blind Testing

- [ ] **Simulate color blindness**
  - Accessibility Inspector > Simulator > Color Blindness
  - Test: Protanopia, Deuteranopia, Tritanopia
  - Ensure information is not conveyed by color alone

### 4. Touch Targets & Motor Control

#### Minimum Touch Targets

- [ ] **All interactive elements ≥ 44×44 pts**
  - Buttons, toggles, links
  - Use `.accessibilityTapTargetSize()` if needed

- [ ] **Adequate spacing between targets**
  - Minimum 8pt spacing between tappable elements
  - Reduce accidental taps

#### Gesture Support

- [ ] **Standard gestures work**
  - Single tap for selection
  - Swipe for dismissal (where appropriate)
  - Long press for context menus

- [ ] **No reliance on complex gestures**
  - Provide alternative actions
  - Example: Swipe to delete + delete button

### 5. Reduce Motion

#### Animation Tests

- [ ] **Test with Reduce Motion enabled**
  - Settings > Accessibility > Motion > Reduce Motion
  - Animations crossfade instead of scale/move
  - No jarring transitions

- [ ] **Code review for motion**
```swift
// ✅ Good - respects reduce motion
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .spring()
}
```

### 6. Hearing & Audio

- [ ] **No audio-only feedback**
  - All audio has visual alternative
  - Alerts show on screen

- [ ] **Captions for video** (if applicable)
  - Not applicable for 1.0

### 7. Screen Reader Optimizations

#### Custom Accessibility Labels

Check these files for proper labels:

**ChatView.swift**
```swift
.accessibilityLabel("Chat message from \(message.role)")
.accessibilityHint("Double tap to view details")
```

**MessageBubbleView.swift**
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel(combinedLabel)
```

**ChatInputView.swift**
```swift
.accessibilityLabel("Message input")
.accessibilityHint("Type your message, then tap send")
```

#### Navigation

- [ ] **Logical reading order**
  - VoiceOver reads top to bottom, left to right
  - Use `accessibilitySortPriority` if needed

- [ ] **Grouped elements** make sense
  - Related controls grouped
  - Headers separate sections

### 8. Keyboard & External Input

- [ ] **External keyboard navigation works**
  - Tab between fields
  - Return to submit
  - Escape to dismiss

- [ ] **Focus indicators visible**
  - Blue outline on focused elements
  - Custom focus styles if needed

### 9. Documentation & Settings

- [ ] **Accessibility statement** in About
  - List accessibility features
  - Contact for issues

- [ ] **No accessibility-blocking features**
  - Don't use `accessibilityHidden` unnecessarily
  - Don't disable system features

### 10. Specific Component Checks

#### Settings Tabs
- File: `OpenResponses/Features/Settings/Views/SettingsHomeView.swift`
- Lines: 23-30 (Picker with tabs)
- [ ] Each tab has clear label
- [ ] Selected state announced

#### Model Selector
- File: `OpenResponses/Features/Settings/Components/DynamicModelSelector.swift`
- [ ] Model names are readable
- [ ] Selection announced clearly

#### Prompt Library
- File: `OpenResponses/Features/Chat/Components/PromptLibraryView.swift`
- [ ] Each prompt card has full description
- [ ] Actions clearly labeled

## Testing Procedure

### Manual Testing Steps

1. **Enable VoiceOver**
   ```
   Settings > Accessibility > VoiceOver > ON
   ```

2. **Navigate through each screen**
   - One-finger swipe right to move forward
   - Two-finger swipe down to read all
   - Double-tap to activate

3. **Test all major flows**
   - Start a conversation
   - Change settings
   - Upload a file
   - Connect an MCP server

4. **Document issues**
   - Screenshot + description
   - File in issue tracker
   - Priority: Critical / High / Medium / Low

### Automated Testing

Use Accessibility Inspector in Xcode:

```bash
# Run audit
1. Open Accessibility Inspector
2. Select simulator/device
3. Click "Audit" tab
4. Run inspection
5. Review warnings/errors
```

### Regression Testing

Add UI tests for accessibility:

```swift
// OpenResponsesUITests/AccessibilityTests.swift
func testVoiceOverLabels() {
    let app = XCUIApplication()
    app.launch()
    
    XCTAssertTrue(app.buttons["Send message"].exists)
    XCTAssertTrue(app.textFields["Message input"].exists)
}
```

## Common Issues & Fixes

### Issue: Missing Label

**Problem:**
```swift
Button(action: send) {
    Image(systemName: "paperplane.fill")
}
```

**Fix:**
```swift
Button(action: send) {
    Image(systemName: "paperplane.fill")
}
.accessibilityLabel("Send message")
```

### Issue: Incorrect Traits

**Problem:** Button labeled as "image"

**Fix:**
```swift
.accessibilityAddTraits(.isButton)
```

### Issue: Complex View Not Grouped

**Problem:** Each word read separately

**Fix:**
```swift
VStack {
    Text("Temperature")
    Slider(value: $temp)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Temperature slider, \(temp)")
```

## Priority Matrix

| Issue | Impact | Effort | Priority |
|-------|--------|--------|----------|
| Missing labels on primary actions | High | Low | **Critical** |
| Poor Dynamic Type support | High | Medium | **High** |
| Low contrast in dark mode | Medium | Low | **High** |
| Complex gestures required | Medium | High | **Medium** |
| Missing hints | Low | Low | **Low** |

## Sign-Off Checklist

Before submitting to App Store:

- [ ] All VoiceOver tests passed
- [ ] Dynamic Type works at all sizes
- [ ] High contrast mode verified
- [ ] Reduce Motion respected
- [ ] Accessibility Inspector audit clean (or issues documented)
- [ ] External keyboard navigation works
- [ ] No reliance on color alone
- [ ] Touch targets meet minimum size
- [ ] Accessibility statement in About view
- [ ] Testing documented in release notes

---

**Last Updated:** 2025-11-08  
**Review Status:** In Progress  
**Next Review:** Before 1.0 release
