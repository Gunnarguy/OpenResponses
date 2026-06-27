from bs4 import BeautifulSoup
import re

with open("docs/OpenAI_API_Reference/realtime_api.md", "r") as f:
    html = f.read()

soup = BeautifulSoup(html, 'html.parser')
# Find all code blocks
pre_tags = soup.find_all('pre')
for i, pre in enumerate(pre_tags):
    text = pre.get_text()
    if "session" in text or "modalities" in text or "audio" in text:
        print(f"--- Block {i} ---")
        lines = text.split("\n")
        for line in lines[:30]:
            print(line)
        if len(lines) > 30:
            print("...")

print("Searching for session.type matches in text:")
for s in soup.find_all(text=re.compile("session\.type")):
    print(s.parent)

