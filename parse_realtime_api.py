import re

with open("docs/OpenAI_API_Reference/realtime_api.md", "r") as f:
    content = f.read()

# Let's find all json code blocks or code snippets containing session or audio
blocks = re.findall(r'```(?:json)?\n(.*?)\n```', content, re.DOTALL)
for i, block in enumerate(blocks):
    if "session" in block or "audio" in block or "modalities" in block:
        print(f"--- Block {i} ---")
        # Print first few lines of the block or lines containing keywords
        lines = block.split("\n")
        for line in lines[:30]:
            print(line)
        if len(lines) > 30:
            print("...")

