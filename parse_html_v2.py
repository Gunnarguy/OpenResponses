import re

with open("docs/OpenAI_API_Reference/realtime_api.md", "r") as f:
    text = f.read()

# Let's clean up HTML tags to make it readable
def clean_html(raw_html):
    cleanr = re.compile('<.*?>')
    cleantext = re.sub(cleanr, ' ', raw_html)
    return cleantext

cleaned = clean_html(text)

# Find all occurrences of session.type or session.update
matches = [m.start() for m in re.finditer("session", cleaned, re.IGNORECASE)]
print(f"Found {len(matches)} occurrences of 'session'.")
for idx, pos in enumerate(matches[:20]):
    start = max(0, pos - 100)
    end = min(len(cleaned), pos + 150)
    print(f"--- Match {idx} ---")
    print(cleaned[start:end].strip().replace('\n', ' '))

