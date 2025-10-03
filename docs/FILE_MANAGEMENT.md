# File Management and Vector Store Integration

This app features an intuitive, redesigned interface for managing files and vector stores with OpenAI's API. The new tabbed interface makes it easy to upload files, organize them into vector stores, and configure file search capabilities.

## New Interface Design

### Tabbed Navigation

The File Manager now features three dedicated tabs for better organization:

1. **Quick Actions** - Common workflows and configuration at your fingertips
2. **Files** - Browse, search, and manage all uploaded files
3. **Vector Stores** - Create, organize, and manage vector stores

### Quick Actions Tab

The Quick Actions tab provides:

- **File Search Configuration**: Enable/disable file search and configure multi-store search (max 2 stores)
- **Active Vector Stores Display**: See which vector stores are currently active with one-tap removal
- **Quick Upload Options**:
  - Upload file directly to a vector store
  - Upload file only (add to vector store later)
  - Create new vector store
- **Statistics Dashboard**: View counts for total files, vector stores, and active stores

### Files Tab

The Files tab offers:

- **Search Bar**: Quickly find files by name
- **Enhanced File Cards**: Each file shows:
  - Filename and size
  - Creation date
  - Quick actions menu for adding to vector stores or deleting
- **Upload Button**: Prominently placed for easy file uploads

### Vector Stores Tab

The Vector Stores tab includes:

- **Search and Filter**:
  - Search vector stores by name
  - Toggle to show only active stores
- **Improved Vector Store Cards**: Each store displays:
  - Name and status indicator
  - File count and storage usage
  - Inline action buttons for "Add Files" and "View Files"
  - Options menu for editing or deleting
- **Create Button**: Easy access to create new vector stores

## Features

### File Management

- **Upload Files**: Upload documents, PDFs, text files, and 43+ other supported formats
- **View Files**: See all uploaded files with searchable list and detailed information
- **Quick Add to Vector Store**: Add files to any vector store directly from the file card
- **Delete Files**: Remove files you no longer need with confirmation dialog
- **Search Files**: Find files quickly using the search bar

### Vector Store Management

- **Create Vector Stores**: Organize files into searchable collections with optional expiration
- **Multi-Store Search**: Enable searching across up to 2 vector stores simultaneously
- **Inline File Management**: Add files to vector stores with one tap
- **View Store Contents**: See all files in a vector store with detailed information
- **Remove Files from Vector Stores**: Manage which files are included in each store
- **Edit Vector Stores**: Update names, metadata, and expiration settings
- **Delete Vector Stores**: Clean up stores you no longer need
- **Smart Selection**: Visual indicators show which stores are active for search

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

## Usage Instructions

### Getting Started with File Search

1. **Access File Manager**:
   - Go to Settings → Tools
   - Toggle on "File Search"
   - Tap "Manage Files & Vector Stores" button

2. **Navigate the Interface**:
   - Use the tab selector at the top to switch between Quick Actions, Files, and Vector Stores
   - Pull down to refresh data in any tab

### Quick Upload Workflow (Recommended)

1. **From Quick Actions Tab**:
   - Tap "Upload File to Vector Store"
   - Select the target vector store from the list
   - Choose your file from the file picker
   - File uploads and is automatically added to the selected store

### Creating and Managing Vector Stores

1. **Create a New Vector Store**:
   - Go to Vector Stores tab (or Quick Actions tab)
   - Tap "Create New Vector Store"
   - Enter a name (optional but recommended)
   - Select files to include (optional)
   - Set expiration period (optional)
   - Tap "Create"

2. **Add Files to Existing Vector Store**:
   - **Option A** (from Vector Store card):
     - Find the vector store in Vector Stores tab
     - Tap the "Add Files" button on the store card
     - Select file from picker
   - **Option B** (from File card):
     - Go to Files tab
     - Tap the menu (•••) on any file card
     - Select "Add to Vector Store"
     - Choose the target vector store

3. **View Vector Store Contents**:
   - In Vector Stores tab, tap "View Files" on any store card
   - See all files, their status, and sizes
   - Swipe left on any file to remove it from the store
   - Tap "Add File" to add more files

### Configuring File Search

1. **Enable File Search**:
   - In Quick Actions tab, toggle "Enable File Search" on

2. **Select Vector Stores**:
   - **Single Store**: Tap the checkbox on any vector store card
   - **Multi-Store** (up to 2):
     - Toggle "Multi-Store Search (Max 2)" on
     - Select up to 2 vector stores by tapping their checkboxes
     - Tap "Save Changes" when done

3. **Active Stores Display**:
   - View active stores in the Quick Actions tab
   - Tap the X to quickly deactivate a store

### Using File Search in Chat

- Once file search is enabled and vector store(s) are selected
- Ask questions about your documents in the chat
- The AI will automatically search through your files to find relevant information
- Multi-store search allows the AI to search across multiple knowledge bases simultaneously

### Using Web Search in Chat

1. **Configure Web Search**:
   - Go to Settings → Tools
   - Toggle on "Web Search" to enable web search functionality
   - Configure settings:
     - **Location Type**: Choose how to provide location context
     - **Timezone**: Select your timezone
     - **Coordinates**: For exact location (if needed)
     - **Search Context Size**: Control search depth
     - **Language & Region**: Set preferences
     - **Max Results**: Adjust result count (5-50)
     - **Safe Search**: Configure content filtering
     - **Recency Filter**: Set time-based filtering

2. **Use in Chat**:
   - Ask questions that require current information or web research
   - The AI will search the web using your configured parameters

### File Formats Supported

The app supports 43+ file formats including:

- Plain text (.txt)
- PDF documents (.pdf)
- JSON files (.json)
- Markdown (.md)
- Code files (.py, .js, .java, .cpp, .cs, etc.)
- Documents (.doc, .docx)
- And many more text-based formats

### Tips

- **Organization**: Organize related documents into the same vector store for better search results
- **Naming**: Use descriptive names for your vector stores to easily identify them
- **Search Scope**: The AI will search through all files in the selected vector store(s)
- **File Status**: Files must be successfully processed (status: "completed") before they can be searched
- **Multi-Store Limit**: You can select up to 2 vector stores for simultaneous search (API limitation)
- **Quick Actions**: Use the Quick Actions tab for the fastest workflows
- **Search & Filter**: Use search bars to quickly find files or vector stores when you have many

### Advanced File Search Features

OpenResponses now supports advanced file search options for power users who need granular control:

#### Max Results Control
- **What**: Limit the number of result chunks returned from vector store search (1-50)
- **Where**: Settings → Tools → File Search → Advanced Search Options → Max Results slider
- **When to Use**: 
  - Lower values (5-15): Quick answers, save tokens, faster responses
  - Higher values (30-50): Deep research, comprehensive context, complex queries
- **Default**: 10 chunks per search

#### Ranking Options
- **What**: Control search result quality and relevance filtering
- **Where**: Settings → Tools → File Search → Advanced Search Options
- **Options**:
  - **Auto**: Let the API choose the best ranking algorithm
  - **Default 2024-08-21**: Use the specific ranking algorithm from August 2024
- **Score Threshold** (0.0-1.0): Filter out low-quality results
  - 0.0: Include all results regardless of relevance
  - 0.5: Moderate filtering, balanced approach
  - 0.7+: High-quality only, may miss some relevant content
  - 1.0: Only perfect matches
- **When to Use**: 
  - Set threshold to 0.6+ when you have very large vector stores
  - Keep at 0.0-0.3 for smaller, curated document sets
  - Increase threshold if getting too many irrelevant results

#### Chunking Strategy (Advanced)
- **What**: Control how files are split into searchable chunks
- **API Support**: Available via `chunking_strategy` parameter when adding files
- **Parameters**:
  - `max_chunk_size_tokens`: 100-4096 tokens per chunk
  - `chunk_overlap_tokens`: 0 to half of max chunk size
- **Defaults**: 800 tokens per chunk, 400 token overlap
- **Best Practices**:
  - Large documents (books, manuals): 2048-4096 token chunks
  - Medium documents (articles, reports): 800-1600 token chunks
  - Short documents (emails, notes): 400-800 token chunks
  - More overlap (400+) improves context preservation across chunks
  - Less overlap saves storage and processing time

#### File Attributes (Advanced)
- **What**: Metadata key-value pairs attached to files for filtering
- **API Support**: Up to 16 keys per file, 256 characters per key
- **Use Cases**:
  - Department/category tagging: `{"department": "sales", "category": "Q1"}`
  - Date-based filtering: `{"year": "2024", "quarter": "Q1"}`
  - Regional filtering: `{"region": "US", "language": "en"}`
  - Custom properties: `{"priority": "high", "status": "reviewed"}`
- **Coming Soon**: UI for managing file attributes in File Manager

#### Attribute Filtering (Advanced)
- **What**: Filter search results using file attributes
- **API Support**: Comparison operators (eq, ne, gt, gte, lt, lte) and compound filters (and, or)
- **Examples**:
  - Search only 2024 documents: `{"type": "eq", "property": "year", "value": "2024"}`
  - Search US sales docs: `{"type": "and", "filters": [{"type": "eq", "property": "region", "value": "US"}, {"type": "eq", "property": "department", "value": "sales"}]}`
- **Coming Soon**: Visual filter builder in File Manager

### Web Search Optimization Tips

- Use **exact location** for highly location-specific queries (local businesses, weather, events)
- Set **high context size** for complex research topics that require comprehensive coverage
- Use **low context size** for quick factual lookups to save processing time
- Choose appropriate **recency filters** for time-sensitive information (news, current events, recent developments)
- Adjust **max results** based on your needs: lower for quick answers, higher for thorough research
- Set **language and region** preferences to get more relevant, culturally appropriate results
- Use **moderate safe search** for general use, **strict** for sensitive topics, **off** for academic research

## API Integration

The app uses OpenAI's Files API and Vector Stores API to provide these features:

- Files are uploaded with the "assistants" purpose
- Vector stores are automatically configured for file search
- Multi-store search uses the `vector_store_ids` array parameter (max 2 stores)
- Tool resources are properly configured in chat requests when file search is enabled

### Advanced API Parameters

The app supports these advanced file search parameters:

- **`max_num_results`**: Controls result count (1-50), implemented with UI slider
- **`ranking_options`**: Quality filtering with ranker selection and score threshold
- **`chunking_strategy`**: Custom chunk sizing for optimal search granularity
- **`attributes`**: File metadata for precision filtering
- **`filters`**: Attribute-based search filtering with comparison and compound operators

