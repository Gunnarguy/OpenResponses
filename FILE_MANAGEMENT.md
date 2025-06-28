# File Management and Vector Store Integration

This app now supports comprehensive file management and vector store functionality with OpenAI's API.

## Features

### File Management

- **Upload Files**: Upload documents, PDFs, text files, and other supported formats
- **View Files**: See all uploaded files with details (size, creation date, purpose)
- **Delete Files**: Remove files you no longer need
- **File Search**: Enable file search to allow the AI to search through your uploaded documents

### Vector Store Management

- **Create Vector Stores**: Organize files into searchable collections
- **Add Files to Vector Stores**: Associate specific files with vector stores
- **Remove Files from Vector Stores**: Manage which files are included in each store
- **Delete Vector Stores**: Clean up stores you no longer need
- **Auto-Selection**: Choose which vector store to use for file search

### Usage Instructions

1. **Enable File Search Tool**:

   - Go to Settings → Tools
   - Toggle on "File Search"
   - This will enable the "Manage Files & Vector Stores" button

2. **Upload Files**:

   - Tap "Manage Files & Vector Stores" in Settings
   - Navigate to the "Uploaded Files" section
   - Tap "Upload File" and select your document
   - Supported formats: PDF, TXT, JSON, and other text-based files

3. **Create a Vector Store**:

   - In the "Vector Stores" section, tap "Create Vector Store"
   - Give it a name (optional)
   - Select which files to include
   - Tap "Create"

4. **Select Vector Store for Search**:

   - Tap on a vector store in the list to select it
   - Selected stores will show a checkmark
   - Only one vector store can be selected at a time

5. **Use File Search in Chat**:
   - Once file search is enabled and a vector store is selected
   - Ask questions about your documents in the chat
   - The AI will automatically search through your files to find relevant information

### File Formats Supported

- Plain text (.txt)
- PDF documents (.pdf)
- JSON files (.json)
- Other text-based formats

### Tips

- Organize related documents into the same vector store for better search results
- Use descriptive names for your vector stores
- The AI will only search through files in the currently selected vector store
- Files must be successfully processed (status: "completed") before they can be searched

### API Integration

The app uses OpenAI's Files API and Vector Stores API to provide these features:

- Files are uploaded with the "assistants" purpose
- Vector stores are automatically configured for file search
- Tool resources are properly configured in chat requests when file search is enabled
