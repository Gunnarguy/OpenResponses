import re

with open("docs/OpenAI_API_Reference/realtime_api.md", "r") as f:
    text = f.read()

# Let's clean up HTML tags to make it readable
def clean_html(raw_html):
    cleanr = re.compile('<.*?>')
    cleantext = re.sub(cleanr, ' ', raw_html)
    return cleantext

cleaned = clean_html(text)

# Find all occurrences of "response.output"
matches = [m.start() for m in re.finditer("response\.output", cleaned, re.IGNORECASE)]
for idx, pos in enumerate(matches):
    start = max(0, pos - 150)
    end = min(len(cleaned), pos + 250)
    context = cleaned[start:end].strip().replace('\n', ' ')
    print(f"--- Context {idx} ---")
    print(context)

