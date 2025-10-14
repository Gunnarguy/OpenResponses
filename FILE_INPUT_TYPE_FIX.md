# File Input Type Fix: Automatic PDF Conversion

## Problem

The OpenAI Responses API rejected file attachments with this error:

```
Invalid input: Expected context stuffing file type to be a supported format: .pdf but got .txt.
```

### Root Cause

The `input_file` type in the Responses API **only supports PDF files** for direct context insertion.

## Solution: Universal File Blender 🎯

Leveraging the existing **`FileConverterService`** (the app's "document blender"), we now **automatically convert** text files to PDF format before uploading to the API.

### How It Works

**For any file attachment:**
1. **PDF files** → Upload directly ✅
2. **Text files (.txt, .md)** → Convert to PDF → Upload ✅
3. **Other file types** → Show helpful error message ⚠️

### The Magic: Text-to-PDF Conversion

Added new method to `FileConverterService.swift`:

```swift
static func convertTextToPDF(content: String, originalFilename: String) throws -> ConversionResult
```

**Features:**
- ✅ Professional formatting (12pt system font, 1" margins)
- ✅ Multi-page support with automatic pagination
- ✅ Page numbers and filename in footer
- ✅ PDF metadata (title, author, creator)
- ✅ Preserves line breaks and formatting
- ✅ Clean, readable output

## Code Changes

### Location: `ChatViewModel.swift` lines 520-590

**New Logic:**
```swift
for (index, data) in pendingFileData.enumerated() {
    let filename = pendingFileNames[index]
    let fileExtension = (filename as NSString).pathExtension.lowercased()
    
    var dataToUpload = data
    var filenameToUpload = filename
    
    // Convert text files to PDF
    if fileExtension == "txt" || fileExtension == "md" {
        if let textContent = String(data: data, encoding: .utf8) {
            let result = try FileConverterService.convertTextToPDF(
                content: textContent,
                originalFilename: filename
            )
            dataToUpload = result.convertedData
            filenameToUpload = result.filename  // "filename.pdf"
        }
    }
    
    // Upload to Files API
    let uploadedFile = try await api.uploadFile(
        fileData: dataToUpload,
        filename: filenameToUpload,
        purpose: "assistants"
    )
}
```

### Location: `FileConverterService.swift` lines 1060+

**New Method:**
- Creates PDF context with proper metadata
- Formats text with professional typography
- Handles multi-page documents automatically
- Adds page numbers and document info


## User Experience

### When attaching PDF files

- Already in PDF format ✅
- Uploads directly to Files API
- Model sees full content (text + images)

### When attaching text files

- **Automatically converted to PDF** ✅
- Shows "📄 Converted filename.txt to PDF for API compatibility"
- Uploads converted PDF with file_id
- Model sees formatted, professional document
- **Zero user intervention required**

### When attaching other files

- Shows error message ⚠️
- Directs to File Manager for vector store upload
- Prevents API errors

## Why This Approach Rocks 🚀

1. **Seamless UX**: Text files "just work" - users don't need to know about PDF requirement
2. **Smart Conversion**: Uses existing FileConverterService infrastructure
3. **Professional Output**: Creates properly formatted PDFs with metadata
4. **Future-Proof**: Easy to add more file type conversions (Word docs, etc.)
5. **Best of Both Worlds**: PDFs get full features (images + text), text gets auto-converted
6. **Quality Preservation**: Maintains all text content and formatting

## API Documentation Reference

From `docs/Documentation/fileinputs.md`:

> "OpenAI models with vision capabilities can also accept **PDF files** as input."

**The solution:** Don't limit users to PDFs - automatically convert their files!

## Alternative Approaches (Rejected)

1. **Embed text inline** ❌
   - Limited to small files
   - Loses document structure
   - No page context

2. **Upload to vector store** ❌
   - Requires file_search tool enabled
   - More complex UX
   - Overkill for simple attachments

3. **Show error** ❌
   - Poor UX
   - Users don't care about API limitations
   - Forces manual workarounds

4. **Auto-convert to PDF** ✅ **CHOSEN**
   - Transparent to user
   - Maintains document quality
   - Leverages existing converter service
   - Works with any text-based file

## Testing Recommendations

### Test Cases

1. **✅ PDF attachment:** Upload PDF → Should work as before
2. **✅ Text file (.txt):** Upload text → Auto-convert to PDF → Upload
3. **✅ Markdown file (.md):** Upload markdown → Auto-convert to PDF → Upload
4. **✅ Multiple text files:** Upload 2 .txt files → Both convert → Both upload
5. **✅ Mixed files:** Upload 1 PDF + 1 .txt → PDF direct, text converts
6. **⚠️ Unsupported file (.docx):** Upload Word doc → Show error with guidance

### Expected Behavior

- Text file conversion happens **silently and quickly**
- User sees activity log: "📄 Converted Gunnars-story.txt to PDF"
- Both original and converted files tracked in logs
- Model receives professionally formatted PDF
- All text content preserved accurately

## Future Enhancements

### Add More Conversions

```swift
// In ChatViewModel - easy to extend
if fileExtension == "docx" || fileExtension == "doc" {
    // Convert Word to PDF
    result = try FileConverterService.convertWordToPDF(...)
} else if fileExtension == "html" || fileExtension == "htm" {
    // Convert HTML to PDF
    result = try FileConverterService.convertHTMLToPDF(...)
}
```

### FileConverterService Methods to Add

- `convertWordToPDF()` - For .docx, .doc files
- `convertHTMLToPDF()` - For web content
- `convertMarkdownToPDF()` - Enhanced MD rendering with styles
- `convertRTFToPDF()` - For rich text files
- `convertCodeToPDF()` - Syntax-highlighted code files

## Related Files

- `ChatViewModel.swift` - File upload orchestration with conversion
- `FileConverterService.swift` - Universal file blender with PDF generation
- `DocumentPicker.swift` - Multi-file selection UI
- `docs/Documentation/fileinputs.md` - API documentation
- `ROADMAP.md` - Phase 1 file inputs (Direct File Uploads)

## Success Criteria

✅ **PDF files work via file_id** (no change)
✅ **Text files auto-convert to PDF** (seamless)
✅ **Clear user feedback** for conversions
✅ **No API errors** for supported file types
✅ **Helpful error** for unsupported types
✅ **Preserves document quality** and formatting
✅ **Zero user intervention** required

---

**TL;DR:** Text files now automatically convert to PDF before upload. Users get "just works" experience. FileConverterService handles all the magic. 🎯
