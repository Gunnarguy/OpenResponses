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

### Web Search Customization

- **Location Settings**: Configure geographic relevance for search results
  - Choose between approximate, exact, or disabled location detection
  - Select timezone from major regions (Pacific, Mountain, Central, Eastern, UTC, London, Tokyo, Sydney)
  - Set exact coordinates for precise location-based searches
- **Search Quality**: Control the depth and context of web searches
  - Adjust search context size (low, medium, high)
  - Set maximum number of results per search (5-50)
  - Configure safe search filtering (strict, moderate, off)
- **Language & Region**: Customize search language and regional preferences
  - Select search language (English, Spanish, French, German, Italian, Portuguese, Japanese, Chinese, Korean, Russian)
  - Choose search region (US, Canada, UK, Germany, France, Japan, Australia, Global)
- **Recency Filtering**: Control how recent the search results should be
  - Auto-detect relevance
  - Filter by time period (24 hours, week, month, year)

### Usage Instructions

1. **Enable File Search Tool**:

   - Go to Settings → Tools
   - Toggle on "File Search"
   - This will enable the "Manage Files & Vector Stores" button

2. **Configure Web Search Settings**:

   - Go to Settings → Tools
   - Toggle on "Web Search" to enable web search functionality
   - The Web Search Configuration section will appear with detailed customization options:
     - **Location Type**: Choose how to provide location context to searches
     - **Timezone**: Select your timezone for time-relevant searches
     - **Coordinates**: For exact location, set latitude and longitude
     - **Search Context Size**: Control search depth (low/medium/high)
     - **Language**: Set preferred search language
     - **Region**: Choose regional search preferences
     - **Max Results**: Adjust number of search results (5-50)
     - **Safe Search**: Configure content filtering
     - **Recency Filter**: Set time-based result filtering

3. **Upload Files**:

   - Tap "Manage Files & Vector Stores" in Settings
   - Navigate to the "Uploaded Files" section
   - Tap "Upload File" and select your document
   - Supported formats: PDF, TXT, JSON, and other text-based files

4. **Create a Vector Store**:

   - In the "Vector Stores" section, tap "Create Vector Store"
   - Give it a name (optional)
   - Select which files to include
   - Tap "Create"

5. **Select Vector Store for Search**:

   - Tap on a vector store in the list to select it
   - Selected stores will show a checkmark
   - Only one vector store can be selected at a time

6. **Use File Search in Chat**:

   - Once file search is enabled and a vector store is selected
   - Ask questions about your documents in the chat
   - The AI will automatically search through your files to find relevant information

7. **Use Web Search in Chat**:
   - Once web search is enabled and configured
   - Ask questions that require current information or web-based research
   - The AI will search the web using your configured parameters for location, language, and quality preferences

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
- **Web Search Optimization Tips**:
  - Use **exact location** for highly location-specific queries (local businesses, weather, events)
  - Set **high context size** for complex research topics that require comprehensive coverage
  - Use **low context size** for quick factual lookups to save processing time
  - Choose appropriate **recency filters** for time-sensitive information (news, current events, recent developments)
  - Adjust **max results** based on your needs: lower for quick answers, higher for thorough research
  - Set **language and region** preferences to get more relevant, culturally appropriate results
  - Use **moderate safe search** for general use, **strict** for sensitive topics, **off** for academic research

### API Integration

The app uses OpenAI's Files API and Vector Stores API to provide these features:

- Files are uploaded with the "assistants" purpose
- Vector stores are automatically configured for file search
- Tool resources are properly configured in chat requests when file search is enabled
