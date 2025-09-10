# Images: Generation and Vision

Learn how to generate, edit, and analyze images with OpenAI models.

## Overview

OpenAI models provide powerful capabilities for working with images. You can:

- **[Generate Images](#generate-images):** Create new images from scratch using a text prompt with `gpt-image-1` or DALL·E models.
- **[Edit Images](#edit-images):** Modify existing images based on a new text prompt, including inpainting and outpainting.
- **[Analyze Images (Vision)](#analyze-images-vision):** Provide images as input to models like `gpt-4o` to have them understand, analyze, and answer questions about the visual content.

You can access these capabilities through two primary APIs:

1.  **[Images API (`/v1/images`):](/docs/api-reference/images)** A dedicated API for direct image generation, editing, and creating variations.
2.  **[Responses API (`/v1/responses`):](/docs/api-reference/responses)** A more flexible API where image generation can be used as a `tool` within a larger conversational context, enabling multi-turn editing and more complex workflows.

### Choosing the Right API

- Use the **Images API** for straightforward, single-shot image generation or editing tasks.
- Use the **Responses API** with the `image_generation` tool for conversational, iterative image editing and building integrated, multimodal experiences.

### Model Comparison

| Model             | API Endpoints                                  | Key Use Cases                                                                                                                                         |
| :---------------- | :--------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`gpt-image-1`** | Images API (Generations, Edits), Responses API | Superior instruction following, text rendering in images, detailed editing, leveraging real-world knowledge. The most advanced and recommended model. |
| **DALL·E 3**      | Images API (Generations only)                  | Higher quality and larger resolutions than DALL·E 2.                                                                                                  |
| **DALL·E 2**      | Images API (Generations, Edits, Variations)    | Lower cost, supports concurrent requests, and specialized inpainting/outpainting with masks.                                                          |

---

## Generate Images

You can create images from scratch using a text prompt.

### Using the Responses API

Generating an image is treated as a tool call. This is the most flexible method, allowing for conversational refinement.

```python
from openai import OpenAI
import base64

client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    input="Generate an image of a futuristic city with flying cars and neon signs.",
    tools=[{"type": "image_generation"}],
)

# Extract the base64 image data from the tool call result
image_data = None
for output in response.output:
    if output.type == "image_generation_call":
        image_data = output.result
        break

if image_data:
    with open("futuristic_city.png", "wb") as f:
        f.write(base64.b64decode(image_data))
```

When using the `image_generation` tool, the model may revise your prompt for better results. You can access this via the `revised_prompt` field in the `image_generation_call` object.

### Using the Images API

This is a direct way to generate an image.

```python
from openai import OpenAI
import base64

client = OpenAI()

result = client.images.generate(
    model="gpt-image-1",
    prompt="A photorealistic image of a red panda wearing a tiny chef's hat, cooking a miniature pizza."
)

image_base64 = result.data[0].b64_json
image_bytes = base64.b64decode(image_base64)

with open("red_panda_chef.png", "wb") as f:
    f.write(image_bytes)
```

### Multi-Turn Editing and Refinement

The Responses API excels at iterative editing. You can refine an image over multiple turns by referencing the `previous_response_id` or the specific `image_generation_call` ID.

**Example: Iterative Refinement**

```python
from openai import OpenAI
import base64

client = OpenAI()

# Turn 1: Initial generation
response1 = client.responses.create(
    model="gpt-5",
    input="Generate an image of a serene forest lake at sunrise.",
    tools=[{"type": "image_generation"}],
)

# Save the first image
image_call_1 = next(o for o in response1.output if o.type == "image_generation_call")
with open("lake_sunrise_1.png", "wb") as f:
    f.write(base64.b64decode(image_call_1.result))

# Turn 2: Add an element
response2 = client.responses.create(
    model="gpt-5",
    previous_response_id=response1.id,
    input="Now, add a lone canoe floating on the water.",
    tools=[{"type": "image_generation"}],
)

# Save the second image
image_call_2 = next(o for o in response2.output if o.type == "image_generation_call")
with open("lake_sunrise_2.png", "wb") as f:
    f.write(base64.b64decode(image_call_2.result))
```

---

## Edit Images

You can modify existing images by providing a new prompt. This includes **inpainting**, where you edit a specific portion of an image using a mask.

### Editing with a Mask (Inpainting)

To edit a specific area, provide the source image and a transparent mask. The transparent areas of the mask indicate where the image should be edited. The image and mask must be the same size.

**Example: Adding a flamingo to a pool**

|                                                 Image                                                  |                                                Mask                                                |                                                    Output                                                     |
| :----------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------: |
| ![Lounge](https://raw.githubusercontent.com/GunnarHostetler/OpenResponses/main/docs/assets/lounge.png) | ![Mask](https://raw.githubusercontent.com/GunnarHostetler/OpenResponses/main/docs/assets/mask.png) | ![Result](https://raw.githubusercontent.com/GunnarHostetler/OpenResponses/main/docs/assets/lounge_result.png) |

```python
from openai import OpenAI
client = OpenAI()

result = client.images.edit(
    model="gpt-image-1",
    image=open("sunlit_lounge.png", "rb"),
    mask=open("mask.png", "rb"),
    prompt="A sunlit indoor lounge area with a pool containing a flamingo"
)

# Save the result
```

---

## Analyze Images (Vision)

Models like `gpt-4o` and `gpt-4.1` can "see" and understand images you provide in the input. This allows you to ask questions, get descriptions, and analyze visual content.

### How to Provide Images

You can provide images as input in three ways:

1.  A fully qualified URL.
2.  A Base64-encoded string.
3.  A File ID from the [Files API](/docs/api-reference/files).

**Example: Analyzing an image from a URL**

```python
from openai import OpenAI

client = OpenAI()

response = client.responses.create(
    model="gpt-4o",
    input=[{
        "role": "user",
        "content": [
            {"type": "input_text", "text": "What's in this image?"},
            {
                "type": "input_image",
                "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg",
            },
        ],
    }],
)

print(response.output_text)
```

### Controlling Detail Level

The `detail` parameter (`low`, `high`, or `auto`) controls how the model processes the image, which affects latency and cost.

- `low`: The model receives a 512x512 version. Faster and cheaper for tasks that don't require high detail.
- `high`: The model receives a more detailed view. Better for analyzing small details.

### Limitations

Vision capabilities have some limitations:

- Not suitable for interpreting specialized medical images (e.g., CT scans).
- May struggle with rotated images or very small text.
- Accuracy can be lower for tasks requiring precise spatial reasoning (e.g., chess positions).

---

## Streaming

Both image generation and vision analysis support streaming. For image generation, you can receive partial images as they are being created, providing faster visual feedback.

### Streaming Image Generation

Set `stream=True` and specify the number of `partial_images` you want to receive.

```python
from openai import OpenAI
import base64

client = OpenAI()

stream = client.images.generate(
    prompt="A beautiful painting of a river made of stars, flowing through a cosmic forest.",
    model="gpt-image-1",
    stream=True,
    partial_images=2,
)

for event in stream:
    if event.type == "image_generation.partial_image":
        idx = event.partial_image_index
        image_base64 = event.b64_json
        image_bytes = base64.b64decode(image_base64)
        with open(f"river_of_stars_{idx}.png", "wb") as f:
            f.write(image_bytes)
```

This provides a more interactive experience for users, as they don't have to wait for the final image to be fully rendered.
