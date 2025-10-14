# CSV Vector Store Upload Fix

**Date:** October 5, 2025  
**Issue:** CSV files failing to upload to vector stores with "File type not supported" error  
**Status:** ✅ Fixed

## Problem Summary

Users attempting to upload CSV files to vector stores experienced the following error:

```
❌ Error response: {
  "error": {
    "message": "File type not supported",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
```

### Root Cause

The application has two different file type validation lists in `FileConverterService.swift`:

1. **`openAISupportedExtensions`** - Broader list for general file uploads (includes CSV)
2. **`vectorStoreSupportedExtensions`** - Stricter list for vector store uploads (excludes CSV)

**Vector stores do NOT support CSV files directly.** According to OpenAI's documentation, vector stores only accept these file types:
- Text files: `.txt`, `.md`
- Code files: `.c`, `.cpp`, `.cs`, `.css`, `.go`, `.html`, `.java`, `.js`, `.json`, `.php`, `.py`, `.rb`, `.sh`, `.tex`, `.ts`
- Documents: `.doc`, `.docx`, `.pdf`, `.pptx`

The bug occurred because `FileManagerView.swift` was calling:
```swift
FileConverterService.processFile(url: url)
```

This defaults the `forVectorStore` parameter to `false`, causing the service to validate against the broader file list and skip necessary conversion.

## Solution

Modified `FileManagerView.swift` (line ~894) to explicitly pass the `forVectorStore` parameter:

```swift
// BEFORE
let conversionResult = try await FileConverterService.processFile(url: url)

// AFTER
let isForVectorStore = targetVectorStoreForUpload != nil
let conversionResult = try await FileConverterService.processFile(url: url, forVectorStore: isForVectorStore)
```

### How It Works Now

1. **Detection:** When a CSV file is selected for vector store upload, the system detects `targetVectorStoreForUpload != nil`
2. **Validation:** `FileConverterService` checks the file against `vectorStoreSupportedExtensions`
3. **Conversion:** Since CSV is not in that list, the service automatically converts it to `.txt` format
4. **Upload:** The converted text file is uploaded and successfully added to the vector store

### Conversion Process

The `convertCSVToText` method:
- Reads the CSV data as plain text
- Wraps it in metadata headers (original filename, conversion method, date)
- Saves it with a `_CSV.txt` suffix
- Preserves the tabular structure for searchability

**Example output filename:** `HealthAutoExport-2025-05-01-2025-10-05_CSV.txt`

## Files Modified

1. `/OpenResponses/Features/Chat/Components/FileManagerView.swift` (3 locations)
   - Line ~897: `handleFileImporterResult` - Main file picker result handler
   - Line ~1011: `handleMultipleFileUploads` - Multi-file upload from Data objects
   - Line ~1087: `handleFileSelection` - Single file selection handler
2. `/OpenResponses/Features/Chat/Components/VectorStoreSmartUploadView.swift` (line ~485)
   - Smart upload view for vector stores

**Note:** `DocumentPicker.swift` was evaluated but requires NO changes - it's used for general chat inputs (not vector stores) and correctly uses the default broader file type validation.

## Testing

Users can now upload CSV files to vector stores:
1. Navigate to File Manager
2. Select a vector store
3. Click "Add Files"
4. Select a CSV file
5. The file will be automatically converted to `.txt` and uploaded successfully

## Documentation Impact

No documentation updates needed - this fix makes the actual behavior match the intended design already documented in `FileConverterService.swift`.

## Related Files

- `/OpenResponses/Core/Services/FileConverterService.swift` - Contains conversion logic
- `/docs/FILE_MANAGEMENT.md` - User guide for file uploads
- `/docs/api/Full_API_Reference.md` - API implementation status

## Prevention

The existing architecture was correctly designed to handle this case. The bug was a simple oversight in parameter passing. The detailed logging in the codebase made diagnosis straightforward:

```
🔍 [FileManager] FileConverterService.swift:95 processFile(url:forVectorStore:) -    🎯 Target: General Upload
```

This log line clearly showed the system was treating a vector store upload as a general upload.

## Future Improvements

Consider:
1. Making `forVectorStore` a required parameter (no default value) to prevent similar oversights
2. Adding a compile-time check or warning when uploading to vector stores
3. Displaying conversion previews in the UI before upload
