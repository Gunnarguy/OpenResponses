import urllib.request
import urllib.error

url = "https://api.openai.com/v1/realtime?model=gpt-realtime-2"
req = urllib.request.Request(url, headers={"Authorization": "Bearer dummy", "OpenAI-Beta": "realtime=v1"})

try:
    urllib.request.urlopen(req)
except urllib.error.HTTPError as e:
    print(f"HTTP Status: {e.code}")
    print(f"Reason: {e.reason}")
    print(f"Response: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")

