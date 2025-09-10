# File Management and Usage

This guide explains how to upload, manage, and use files with OpenAI models. Files can be used for various purposes, including providing context for responses, analyzing data, and as a knowledge base for tools like `file_search`.

## Overview

The file management workflow consists of three main steps:

1.  **[Upload Files](#1-upload-files):** Add files to your project using the `/v1/files` endpoint. This makes them accessible to the API.
2.  **[Use Files as Input](#2-use-files-as-input):** Reference uploaded files directly in your API calls, for example, to have a model analyze an image or a document.
3.  **[Attach Files to Vector Stores for Retrieval](#3-attach-files-to-vector-stores-for-retrieval):** For knowledge retrieval, attach files to a `VectorStore` and make it available to the `file_search` tool. This allows the model to intelligently search and cite information from your documents.

---

## 1. Upload Files

You upload files using the `/v1/files` endpoint with a `multipart/form-data` request.

Each file needs a `purpose` which tells the API how the file will be used. The two main purposes are:

- `input`: For files that will be used as direct input to a model (e.g., an image for `gpt-4o` to analyze).
- `file_search`: For files that will be part of a knowledge base for the `file_search` tool.

**Example: Uploading a file for `file_search`**

```python
from openai import OpenAI
client = OpenAI()

# The file must be opened in binary read mode
file_object = client.files.create(
  file=open("my_document.pdf", "rb"),
  purpose="file_search"
)

# The file_object will contain the file ID
print(file_object.id)
# file-abc123...
```

Once uploaded, the file is stored securely and can be referenced by its ID in other API calls.

---

## 2. Use Files as Input

Some models, like `gpt-4o`, can directly analyze the content of files you provide. This is common for multimodal tasks, such as describing an image or summarizing a document.

To use a file as input, you must first upload it with the `input` purpose. Then, you reference its `file_id` in the `input` array of a `/v1/responses` call.

**Example: Asking a question about an uploaded image**

```python
from openai import OpenAI
client = OpenAI()

# 1. Upload the image with 'input' purpose
vision_file = client.files.create(
  file=open("boardwalk.jpg", "rb"),
  purpose="input"
)

# 2. Use the file_id in the Responses API call
response = client.responses.create(
    model="gpt-4o",
    input=[{
        "role": "user",
        "content": [
            {"type": "input_text", "text": "Describe this image in one sentence."},
            {
                "type": "input_file",
                "file_id": vision_file.id,
            },
        ],
    }],
)

print(response.output_text)
```

This approach is simpler than Base64 encoding for large files and allows you to reuse the same uploaded file across multiple API calls.

---

## 3. Attach Files to Vector Stores for Retrieval

For knowledge retrieval, you use the `file_search` tool. This tool requires files to be associated with a **Vector Store**. A Vector Store preprocesses your files by chunking them, creating embeddings, and indexing them for efficient search.

### Workflow for `file_search`

#### Step A: Create a Vector Store

A Vector Store is a container for your files. You can create one and reuse it across multiple conversations.

```python
from openai import OpenAI
client = OpenAI()

vector_store = client.beta.vector_stores.create(
  name="Product Documentation"
)
```

#### Step B: Upload and Attach Files

Upload your files with the `file_search` purpose and attach them to the Vector Store. You can do this in one step.

```python
from openai import OpenAI
client = OpenAI()

# Path to your files
file_paths = ["doc1.pdf", "doc2.md"]
file_streams = [open(path, "rb") for path in file_paths]

# Upload and attach the files to the vector store
file_batch = client.beta.vector_stores.file_batches.upload_and_poll(
  vector_store_id=vector_store.id,
  files=file_streams
)

# You can check the status of the file batch
print(file_batch.status)
print(file_batch.file_counts)
```

The files are now indexed and ready for searching.

#### Step C: Use the `file_search` Tool

In your `/v1/responses` call, enable the `file_search` tool and provide the `vector_store_id`. The model will automatically search the relevant documents and include citations in its response.

```python
from openai import OpenAI
client = OpenAI()

# Create a response and pass the vector store to the tool
response = client.responses.create(
    model="gpt-5",
    input="What are the new features in the latest product update? Cite the documents.",
    tools=[{
        "type": "file_search",
        "vector_store_ids": [vector_store.id]
    }]
)

# The model's response will contain annotations
print(response.output_text)
```

The output will include annotations like `[doc-1]` that link to the source passages, which you can retrieve from the `tool_calls` in the response object. This ensures that answers are grounded in your provided documents and are verifiable.
